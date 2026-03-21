import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/shared/business_type/utils/role_label_utils.dart';
import '../../data/models/tenant_user.dart';
import '../../data/services/admin_api_service.dart';
import '../providers/admin_providers.dart';

const List<String> _kAssignableRoles = ['manager', 'commercial', 'cashier'];

class TenantUsersTab extends ConsumerWidget {
  final String tenantId;

  const TenantUsersTab({super.key, required this.tenantId});

  String get _token {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(tenantUsersProvider(tenantId));

    return Scaffold(
      body: usersAsync.when(
        data: (users) => users.isEmpty
            ? const Center(child: Text('Aucun utilisateur'))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (ctx, i) => _UserTile(
                  user: users[i],
                  onMoreTap: () => _showOptions(ctx, ref, users[i]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-user-$tenantId',
        onPressed: () => _showAddUserDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, TenantUser user) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Changer le rôle'),
              onTap: () {
                Navigator.pop(context);
                _showRoleChangeDialog(context, ref, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.red),
              title: const Text('Désactiver l\'accès',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, ref, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleChangeDialog(
      BuildContext context, WidgetRef ref, TenantUser user) {
    showDialog(
      context: context,
      builder: (_) => RoleChangeDialog(
        currentRole: user.role,
        onConfirm: (newRole) async {
          try {
            await ref.read(adminApiServiceProvider).updateUserRole(
                  tenantId,
                  user.userId,
                  newRole,
                  token: _token,
                );
            ref.invalidate(tenantUsersProvider(tenantId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rôle mis à jour')));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, WidgetRef ref, TenantUser user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la désactivation'),
        content:
            Text('Désactiver l\'accès de ${user.email} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminApiServiceProvider).removeUser(
                      tenantId,
                      user.userId,
                      token: _token,
                    );
                ref.invalidate(tenantUsersProvider(tenantId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Utilisateur désactivé')));
                }
              } on AdminApiException catch (e) {
                if (context.mounted) {
                  final msg = e.code == 'CANNOT_REMOVE_LAST_OWNER'
                      ? 'Impossible de supprimer le dernier owner'
                      : 'Erreur: ${e.code}';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(msg), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AddUserDialog(
        onSubmit: (email, password, role) async {
          await ref.read(adminApiServiceProvider).createTenantUser(
                tenantId,
                email: email,
                password: password,
                role: role,
                token: _token,
              );
          ref.invalidate(tenantUsersProvider(tenantId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Utilisateur ajouté')));
          }
        },
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final TenantUser user;
  final VoidCallback onMoreTap;

  const _UserTile({required this.user, required this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    final initial = user.email.isNotEmpty ? user.email[0].toUpperCase() : '?';
    final lastSignIn = user.lastSignInAt != null
        ? _formatDate(user.lastSignInAt!)
        : 'Jamais';

    return ListTile(
      leading: CircleAvatar(child: Text(initial)),
      title: Text(user.email),
      subtitle: Text('Rôle : ${getRoleLabel(user.role, {})} • Dernière connexion : $lastSignIn'),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: onMoreTap,
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── AddUserDialog ─────────────────────────────────────────────────────────────

class AddUserDialog extends StatefulWidget {
  final Future<void> Function(String email, String password, String role)
      onSubmit;

  const AddUserDialog({super.key, required this.onSubmit});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'manager';
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSubmit(_emailCtrl.text.trim(), _passwordCtrl.text, _role);
      if (mounted) Navigator.pop(context);
    } on AdminApiException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'EMAIL_ALREADY_EXISTS'
          ? 'Cet email est déjà utilisé'
          : 'Erreur: ${e.code}';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un utilisateur'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email obligatoire';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) return 'Au moins 8 caractères';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: _kAssignableRoles
                  .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(getRoleLabel(r, {})),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? _role),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Ajouter'),
        ),
      ],
    );
  }
}

// ── RoleChangeDialog ──────────────────────────────────────────────────────────

class RoleChangeDialog extends StatefulWidget {
  final String currentRole;
  final Future<void> Function(String role) onConfirm;

  const RoleChangeDialog(
      {super.key, required this.currentRole, required this.onConfirm});

  @override
  State<RoleChangeDialog> createState() => _RoleChangeDialogState();
}

class _RoleChangeDialogState extends State<RoleChangeDialog> {
  late String _role;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _role = _kAssignableRoles.contains(widget.currentRole)
        ? widget.currentRole
        : _kAssignableRoles.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le rôle'),
      content: DropdownButtonFormField<String>(
        initialValue: _role,
        items: _kAssignableRoles
            .map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(getRoleLabel(r, {})),
                ))
            .toList(),
        onChanged: (v) => setState(() => _role = v ?? _role),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  final nav = Navigator.of(context);
                  setState(() => _loading = true);
                  await widget.onConfirm(_role);
                  if (mounted) nav.pop();
                },
          child: _loading
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}
