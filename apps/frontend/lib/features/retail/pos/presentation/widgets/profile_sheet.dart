import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/data/services/employee_pin_service.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => SingleChildScrollView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: const _ProfileSheetContent(),
      ),
    ),
  );
}

class _ProfileSheetContent extends ConsumerStatefulWidget {
  const _ProfileSheetContent();

  @override
  ConsumerState<_ProfileSheetContent> createState() =>
      _ProfileSheetContentState();
}

class _ProfileSheetContentState extends ConsumerState<_ProfileSheetContent> {
  bool _saving = false;

  // name
  final _nameCtrl = TextEditingController();
  bool _nameInitialized = false;
  bool _editingName = false;

  // password (Supabase user only)
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  bool _pwObscure = true;
  bool _editingPw = false;

  // PIN (all users — employee local OR Supabase user)
  final _pinCtrl = TextEditingController();
  final _pinConfirmCtrl = TextEditingController();
  bool _editingPin = false;
  String? _existingPin; // loaded async for Supabase users
  bool _pinLoaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────────

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF1A73E8), Color(0xFF34A853), Color(0xFFEA4335),
      Color(0xFFFBBC04), Color(0xFF9C27B0), Color(0xFF00BCD4),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  // ── save name ────────────────────────────────────────────────────────────────

  Future<void> _saveName(EmployeeProfile? employee) async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;
    setState(() => _saving = true);
    try {
      if (employee != null) {
        final service = ref.read(employeePinServiceProvider);
        final all = await service.getEmployees();
        final updated = all.map((e) => e.id == employee.id
            ? EmployeeProfile(id: e.id, name: newName, pin: e.pin, color: e.color)
            : e).toList();
        await service.saveEmployees(updated);
        ref.read(selectedEmployeeProvider.notifier).state = EmployeeProfile(
          id: employee.id, name: newName, pin: employee.pin, color: employee.color,
        );
      } else {
        await ref.read(authRepositoryProvider).updateFullName(newName);
        ref.invalidate(userProfileProvider);
      }
      if (mounted) setState(() => _editingName = false);
      _snack('Nom mis à jour', success: true);
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── save password ────────────────────────────────────────────────────────────

  Future<void> _savePassword() async {
    final pw = _pwCtrl.text;
    if (pw.length < 6) { _snack('Minimum 6 caractères'); return; }
    if (pw != _pwConfirmCtrl.text) { _snack('Les mots de passe ne correspondent pas'); return; }
    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(pw);
      _pwCtrl.clear(); _pwConfirmCtrl.clear();
      if (mounted) setState(() => _editingPw = false);
      _snack('Mot de passe mis à jour', success: true);
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── save PIN ─────────────────────────────────────────────────────────────────

  Future<void> _savePin({EmployeeProfile? employee, String? userId}) async {
    final pin = _pinCtrl.text;
    if (pin.length != 4) { _snack('PIN doit contenir 4 chiffres'); return; }
    if (pin != _pinConfirmCtrl.text) { _snack('Les PIN ne correspondent pas'); return; }
    setState(() => _saving = true);
    try {
      final service = ref.read(employeePinServiceProvider);
      if (employee != null) {
        // Local employee profile
        final all = await service.getEmployees();
        final updated = all.map((e) => e.id == employee.id
            ? EmployeeProfile(id: e.id, name: e.name, pin: pin, color: e.color)
            : e).toList();
        await service.saveEmployees(updated);
        ref.read(selectedEmployeeProvider.notifier).state = EmployeeProfile(
          id: employee.id, name: employee.name, pin: pin, color: employee.color,
        );
      } else if (userId != null) {
        // Supabase-authenticated user
        await service.saveUserPin(userId, pin);
        if (mounted) setState(() => _existingPin = pin);
      }
      _pinCtrl.clear(); _pinConfirmCtrl.clear();
      if (mounted) setState(() => _editingPin = false);
      _snack('PIN mis à jour', success: true);
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? kSheetGreen : kSheetRed,
    ));
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(selectedEmployeeProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isEmployee = employee != null;

    final displayName = employee?.name ?? user?.fullName ?? user?.email ?? 'Utilisateur';
    final subtitle = isEmployee ? 'Profil caissier (local)' : (user?.email ?? '');

    // Initialize name field once we have the real value
    if (!_nameInitialized && displayName != 'Utilisateur') {
      _nameCtrl.text = displayName;
      _nameInitialized = true;
    }

    final color = _avatarColor(displayName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── drag handle ──────────────────────────────────────────────────────
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── avatar + identity ────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_initials(displayName),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kSheetSlate900)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: kSheetSlate500)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        // ── NOM ──────────────────────────────────────────────────────────────
        _SectionLabel(
          label: 'Nom affiché',
          actionLabel: _editingName ? null : 'Modifier',
          onAction: () => setState(() => _editingName = true),
        ),
        const SizedBox(height: 8),
        if (_editingName) ...[
          TextFormField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: sheetInputDecoration(label: 'Nom complet'),
          ),
          const SizedBox(height: 10),
          _Buttons(
            saving: _saving,
            onCancel: () => setState(() {
              _nameCtrl.text = displayName;
              _editingName = false;
            }),
            onSave: _saving ? null : () => _saveName(employee),
          ),
        ] else
          Text(displayName,
              style: const TextStyle(fontSize: 14, color: kSheetSlate900)),

        // ── MOT DE PASSE (Supabase uniquement) ────────────────────────────────
        if (!isEmployee) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          _SectionLabel(
            label: 'Mot de passe',
            actionLabel: _editingPw ? null : 'Modifier',
            onAction: () => setState(() => _editingPw = true),
          ),
          const SizedBox(height: 8),
          if (_editingPw) ...[
            TextFormField(
              controller: _pwCtrl,
              obscureText: _pwObscure,
              decoration: sheetInputDecoration(label: 'Nouveau mot de passe').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_pwObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _pwObscure = !_pwObscure),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pwConfirmCtrl,
              obscureText: _pwObscure,
              decoration: sheetInputDecoration(label: 'Confirmer le mot de passe'),
            ),
            const SizedBox(height: 10),
            _Buttons(
              saving: _saving,
              onCancel: () {
                _pwCtrl.clear(); _pwConfirmCtrl.clear();
                setState(() => _editingPw = false);
              },
              onSave: _saving ? null : _savePassword,
            ),
          ] else
            const Text('••••••••',
                style: TextStyle(fontSize: 14, color: kSheetSlate500)),
        ],

        // ── PIN (tous les utilisateurs POS) ──────────────────────────────────
        ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          () {
            // Load PIN once for Supabase users
            if (!_pinLoaded && !isEmployee && user != null) {
              _pinLoaded = true;
              ref.read(employeePinServiceProvider).getUserPin(user.id).then((p) {
                if (mounted) setState(() => _existingPin = p);
              });
            }
            final hasPinSet = isEmployee || _existingPin != null;
            return _SectionLabel(
              label: 'Code PIN (4 chiffres)',
              actionLabel: _editingPin ? null : (hasPinSet ? 'Modifier' : 'Créer'),
              onAction: () => setState(() => _editingPin = true),
            );
          }(),
          const SizedBox(height: 8),
          if (_editingPin) ...[
            TextFormField(
              controller: _pinCtrl,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: sheetInputDecoration(label: 'Nouveau PIN'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pinConfirmCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: sheetInputDecoration(label: 'Confirmer le PIN'),
            ),
            const SizedBox(height: 10),
            _Buttons(
              saving: _saving,
              onCancel: () {
                _pinCtrl.clear(); _pinConfirmCtrl.clear();
                setState(() => _editingPin = false);
              },
              onSave: _saving ? null : () => _savePin(
                employee: employee,
                userId: isEmployee ? null : user?.id,
              ),
            ),
          ] else if (isEmployee || _existingPin != null)
            Row(
              children: [
                const Text('••••',
                    style: TextStyle(fontSize: 22, letterSpacing: 8, color: kSheetSlate500)),
                const SizedBox(width: 12),
                const Text('PIN configuré',
                    style: TextStyle(fontSize: 12, color: kSheetSlate500)),
              ],
            )
          else
            const Text('Aucun PIN — appuyez sur Créer',
                style: TextStyle(fontSize: 14, color: kSheetSlate500)),
        ],

        const SizedBox(height: 8),
      ],
    );
  }
}

// ── widgets helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionLabel({required this.label, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: kSheetSlate500)),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kSheetBlue)),
          ),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  final bool saving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  const _Buttons({required this.saving, this.onCancel, this.onSave});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: sheetCancelButtonStyle(),
            onPressed: onCancel,
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton(
            style: sheetPrimaryButtonStyle(),
            onPressed: onSave,
            child: saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }
}
