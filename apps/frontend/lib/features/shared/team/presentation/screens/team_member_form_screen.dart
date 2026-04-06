import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

// ── Role + permissions config ─────────────────────────────────────────────────

class _PermEntry {
  final IconData icon;
  final String label;
  final bool granted;
  final String? note;

  const _PermEntry({
    required this.icon,
    required this.label,
    required this.granted,
    this.note,
  });
}

const _kRoleOptions = [
  (code: 'commercial', label: 'Vendeur', desc: 'Accès POS uniquement'),
  (code: 'manager', label: 'Responsable', desc: 'POS + Stock + Rapports partiels'),
  (code: 'owner', label: 'Propriétaire', desc: 'Accès complet à tout'),
];

List<_PermEntry> _permsFor(String role) {
  switch (role) {
    case 'commercial':
      return const [
        _PermEntry(icon: Icons.point_of_sale, label: 'Caisse (POS)', granted: true),
        _PermEntry(icon: Icons.receipt_long, label: 'Historique de ses ventes', granted: true),
        _PermEntry(icon: Icons.inventory_2_outlined, label: 'Stock & Inventaire', granted: false),
        _PermEntry(icon: Icons.analytics_outlined, label: 'Rapports', granted: false),
        _PermEntry(icon: Icons.settings_outlined, label: 'Paramètres', granted: false),
        _PermEntry(icon: Icons.people_outline, label: 'Équipe', granted: false),
      ];
    case 'manager':
      return const [
        _PermEntry(icon: Icons.point_of_sale, label: 'Caisse (POS)', granted: true),
        _PermEntry(icon: Icons.receipt_long, label: 'Historique ventes (toutes)', granted: true),
        _PermEntry(icon: Icons.inventory_2_outlined, label: 'Stock & Inventaire', granted: true),
        _PermEntry(icon: Icons.call_received_outlined, label: 'Achats & Réceptions', granted: true),
        _PermEntry(
          icon: Icons.analytics_outlined,
          label: 'Rapports partiels',
          granted: true,
          note: 'Pas de CA global',
        ),
        _PermEntry(icon: Icons.settings_outlined, label: 'Paramètres', granted: false),
        _PermEntry(icon: Icons.people_outline, label: 'Équipe', granted: false),
      ];
    case 'owner':
    default:
      return const [
        _PermEntry(icon: Icons.point_of_sale, label: 'Caisse (POS)', granted: true),
        _PermEntry(icon: Icons.receipt_long, label: 'Historique ventes complet', granted: true),
        _PermEntry(icon: Icons.inventory_2_outlined, label: 'Stock & Inventaire', granted: true),
        _PermEntry(icon: Icons.call_received_outlined, label: 'Achats & Réceptions', granted: true),
        _PermEntry(icon: Icons.analytics_outlined, label: 'Rapports complets', granted: true),
        _PermEntry(icon: Icons.settings_outlined, label: 'Paramètres boutique', granted: true),
        _PermEntry(icon: Icons.people_outline, label: 'Gestion équipe', granted: true),
      ];
  }
}

Color _roleColor(String role) => switch (role) {
      'commercial' => const Color(0xFF0D9488),
      'manager' => const Color(0xFF7C3AED),
      _ => AppColors.primary,
    };

// ── Screen ────────────────────────────────────────────────────────────────────

/// [existingUser] — if set, this is an edit; if null, this is a creation.
class TeamMemberFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingUser;

  const TeamMemberFormScreen({super.key, this.existingUser});

  @override
  ConsumerState<TeamMemberFormScreen> createState() =>
      _TeamMemberFormScreenState();
}

class _TeamMemberFormScreenState
    extends ConsumerState<TeamMemberFormScreen> {
  late String _selectedRole;
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool get _isEdit => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    if (u != null) {
      _selectedRole = u['role'] as String? ?? 'commercial';
      _nameCtrl.text = u['fullName'] as String? ?? '';
      _emailCtrl.text = u['email'] as String? ?? '';
    } else {
      _selectedRole = 'commercial';
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final tenantId = ref.read(activeTenantProvider) ?? '';
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    if (!_isEdit && _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('L\'adresse e-mail est requise.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      http.Response response;

      if (_isEdit) {
        final userId = widget.existingUser!['userId'] as String;
        response = await http.patch(
          Uri.parse(
              '${ApiConstants.baseUrl}/organizations/$tenantId/members/$userId'),
          headers: ApiConstants.headers(tenantId: tenantId, token: token),
          body: jsonEncode({'role': _selectedRole}),
        ).timeout(const Duration(seconds: 15));
      } else {
        final body = <String, dynamic>{
          'email': _emailCtrl.text.trim(),
          'role': _selectedRole,
        };
        if (_nameCtrl.text.trim().isNotEmpty) {
          body['fullName'] = _nameCtrl.text.trim();
        }
        response = await http.post(
          Uri.parse(
              '${ApiConstants.baseUrl}/organizations/$tenantId/invite'),
          headers: ApiConstants.headers(tenantId: tenantId, token: token),
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 15));
      }

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Rôle mis à jour.'
                : 'Invitation envoyée à ${_emailCtrl.text.trim()}.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ${response.statusCode}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ScalarioAppBar(
        title: _isEdit ? 'Modifier le membre' : 'Nouveau membre',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Form card ───────────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informations',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _FieldLabel('Adresse e-mail *'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: _isEdit,
                    style: TextStyle(
                      color: _isEdit
                          ? AppColors.textSecondary
                          : null,
                    ),
                    decoration: _inputDeco(
                      hint: 'exemple@domaine.com',
                      filled: _isEdit,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Full name
                  _FieldLabel(
                      'Nom complet${_isEdit ? '' : ' (optionnel)'}'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    readOnly: _isEdit,
                    style: TextStyle(
                      color: _isEdit
                          ? AppColors.textSecondary
                          : null,
                    ),
                    decoration: _inputDeco(
                      hint: 'Ex : Bernard Ouédraogo',
                      filled: _isEdit,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Role selector ────────────────────────────────────────────────
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rôle',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ..._kRoleOptions.map((r) => _RoleRadioCard(
                        code: r.code,
                        label: r.label,
                        desc: r.desc,
                        selected: _selectedRole == r.code,
                        onTap: () =>
                            setState(() => _selectedRole = r.code),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Permissions panel ────────────────────────────────────────────
            _PermissionsPanel(role: _selectedRole),

            const SizedBox(height: 24),

            // ── CTA ──────────────────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit
                            ? 'Enregistrer les modifications'
                            : 'Envoyer l\'invitation',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),

            if (_isEdit) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco({String? hint, bool filled = false}) {
    const radius = BorderRadius.all(Radius.circular(10));
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      filled: true,
      fillColor: filled ? AppColors.background : Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: const OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }
}

// ── Role radio card ───────────────────────────────────────────────────────────

class _RoleRadioCard extends StatelessWidget {
  final String code;
  final String label;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _RoleRadioCard({
    required this.code,
    required this.label,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(code);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? color : AppColors.border, width: 2),
                color: selected ? color : Colors.white,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Permissions panel ─────────────────────────────────────────────────────────

class _PermissionsPanel extends StatelessWidget {
  final String role;
  const _PermissionsPanel({required this.role});

  @override
  Widget build(BuildContext context) {
    final perms = _permsFor(role);
    final color = _roleColor(role);
    final label = _kRoleOptions
        .firstWhere((r) => r.code == role,
            orElse: () => (code: role, label: role, desc: ''))
        .label;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Permissions',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...perms.map((p) => _PermRow(entry: p)),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final _PermEntry entry;
  const _PermRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            entry.granted ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: entry.granted
                ? AppColors.success
                : AppColors.textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.label,
              style: TextStyle(
                fontSize: 13,
                color: entry.granted
                    ? null
                    : AppColors.textSecondary.withValues(alpha: 0.7),
                decoration:
                    entry.granted ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          if (entry.note != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                entry.note!,
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Shared atoms ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary),
    );
  }
}
