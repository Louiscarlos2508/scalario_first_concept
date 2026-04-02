import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/data/services/employee_pin_service.dart';
import 'package:frontend/features/retail/pos/presentation/screens/employee_pin_screen.dart';

/// Owner-facing screen to manage POS employee PIN profiles.
///
/// These are local SharedPreferences profiles — distinct from Supabase auth
/// users. They identify who is operating the shared POS terminal each shift.
class TeamPinScreen extends StatefulWidget {
  const TeamPinScreen({super.key});

  @override
  State<TeamPinScreen> createState() => _TeamPinScreenState();
}

class _TeamPinScreenState extends State<TeamPinScreen> {
  final _service = EmployeePinService();
  List<EmployeeProfile> _employees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _service.getEmployees();
    if (mounted) setState(() { _employees = list; _loading = false; });
  }

  Future<void> _save() async {
    await _service.saveEmployees(_employees);
  }

  Future<void> _openEditor({EmployeeProfile? existing}) async {
    final result = await showDialog<EmployeeProfile>(
      context: context,
      builder: (_) => _EmployeeEditorDialog(existing: existing),
    );
    if (result == null) return;

    setState(() {
      if (existing == null) {
        _employees.add(result);
      } else {
        final idx = _employees.indexWhere((e) => e.id == existing.id);
        if (idx >= 0) _employees[idx] = result;
      }
    });
    await _save();
  }

  Future<void> _delete(EmployeeProfile employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
            'Supprimer ${employee.name} ? Son PIN ne sera plus accepté à la caisse.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _employees.removeWhere((e) => e.id == employee.id));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ScalarioAppBar(title: 'Caissiers & PINs'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Ajouter'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.badge_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Aucun caissier configuré',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ajoutez les membres de votre équipe pour qu\'ils\npuissent s\'identifier à la caisse avec leur PIN.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Ajouter un caissier'),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _employees.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = _employees[i];
        return _EmployeeTile(
          employee: e,
          onEdit: () => _openEditor(existing: e),
          onDelete: () => _delete(e),
        );
      },
    );
  }
}

// ── Employee tile ─────────────────────────────────────────────────────────────

class _EmployeeTile extends StatelessWidget {
  final EmployeeProfile employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeTile({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: EmployeeAvatar(employee: employee, size: 42),
        title: Text(employee.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${employee.pin.length} chiffres · PIN configuré',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Modifier',
              onPressed: onEdit,
              color: AppColors.primary,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Supprimer',
              onPressed: onDelete,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Editor dialog ─────────────────────────────────────────────────────────────

const _kColorPresets = [
  '#1A73E8', // blue
  '#34A853', // green
  '#EA4335', // red
  '#FBBC04', // yellow
  '#9C27B0', // purple
  '#FF6D00', // orange
];

class _EmployeeEditorDialog extends StatefulWidget {
  final EmployeeProfile? existing;
  const _EmployeeEditorDialog({this.existing});

  @override
  State<_EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<_EmployeeEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pinCtrl;
  late String _selectedColor;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _pinCtrl = TextEditingController(
        text: widget.existing?.pin ?? '');
    _selectedColor =
        widget.existing?.color ?? _kColorPresets.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final pin = _pinCtrl.text.trim();

    if (name.isEmpty) return;

    if (pin.isEmpty || pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _pinError = 'PIN doit être 4 chiffres');
      return;
    }

    final profile = EmployeeProfile(
      id: widget.existing?.id ??
          'emp-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      pin: pin,
      color: _selectedColor,
    );
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifier le caissier' : 'Ajouter un caissier'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Center(
              child: EmployeeAvatar(
                employee: EmployeeProfile(
                  id: '',
                  name: _nameCtrl.text.isEmpty ? '?' : _nameCtrl.text,
                  pin: '',
                  color: _selectedColor,
                ),
                size: 56,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // PIN
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Code PIN (4 chiffres)',
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: _pinError,
              ),
              onChanged: (_) => setState(() => _pinError = null),
            ),
            const SizedBox(height: 16),

            // Color
            const Text('Couleur',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: _kColorPresets.map((hex) {
                final color = Color(
                    int.parse(hex.replaceFirst('#', '0xFF')));
                final selected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Colors.black45, width: 3)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _nameCtrl.text.trim().isEmpty ? null : _submit,
          child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
        ),
      ],
    );
  }
}
