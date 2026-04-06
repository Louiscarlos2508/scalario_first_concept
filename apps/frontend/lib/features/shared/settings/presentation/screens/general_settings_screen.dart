import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/settings/presentation/widgets/loss_locations_editor.dart';

// Reuse tenantInfoProvider from settings
final _tenantInfoSettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant/my-info'),
    headers: ApiConstants.headers(tenantId: tenantId, token: token),
  ).timeout(const Duration(seconds: 15));
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  return {};
});

// ── Screen ────────────────────────────────────────────────────────────────────

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() =>
      _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState
    extends ConsumerState<GeneralSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _fill(Map<String, dynamic> info) {
    if (_loaded) return;
    _loaded = true;
    _nameCtrl.text = info['name'] as String? ?? '';
    _addressCtrl.text = info['address'] as String? ?? '';
    _phoneCtrl.text = info['phone'] as String? ?? '';
  }

  Future<void> _save() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _saving = true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tenant/my-info'),
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
        body: jsonEncode({
          'name': _nameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(_tenantInfoSettingsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés ✓'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(_tenantInfoSettingsProvider);
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;

    infoAsync.whenData(_fill);

    final businessTypeName = config?.name ??
        infoAsync.valueOrNull?['businessTypeName'] as String? ??
        '—';
    final currency =
        infoAsync.valueOrNull?['currency'] as String? ?? 'XOF';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ScalarioAppBar(title: 'Paramètres — Général'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Identité boutique ────────────────────────────────────────────
            _Card(
              title: 'Identité de la boutique',
              children: [
                // Logo placeholder
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.border,
                          width: 1.5,
                          strokeAlign: BorderSide.strokeAlignOutside),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 24, color: AppColors.textSecondary),
                        const SizedBox(height: 2),
                        Text(
                          'Logo',
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _FieldLabel('Nom de la boutique'),
                const SizedBox(height: 6),
                _inputField(
                    ctrl: _nameCtrl, hint: 'Ma Boutique'),
                const SizedBox(height: 14),
                _FieldLabel('Téléphone'),
                const SizedBox(height: 6),
                _inputField(
                    ctrl: _phoneCtrl,
                    hint: '+226 70 00 00 00',
                    keyboard: TextInputType.phone),
                const SizedBox(height: 14),
                _FieldLabel('Adresse'),
                const SizedBox(height: 6),
                _inputField(
                    ctrl: _addressCtrl,
                    hint: 'Ouaga, Secteur 30',
                    maxLines: 2),
              ],
            ),

            const SizedBox(height: 16),

            // ── Secteur & Devise ──────────────────────────────────────────────
            _Card(
              title: 'Secteur & Devise',
              children: [
                _InfoRow('Type de commerce', businessTypeName),
                const SizedBox(height: 8),
                _InfoRow('Devise', 'FCFA ($currency)'),
                const SizedBox(height: 4),
                Text(
                  'Pour modifier le type ou la devise, contactez votre intégrateur.',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Emplacements de perte ─────────────────────────────────────────
            _Card(
              title: 'Emplacements de perte',
              children: [const LossLocationsEditor()],
            ),

            const SizedBox(height: 16),

            // ── Zone dangereuse ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_outlined,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      const Text(
                        'Zone dangereuse',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La suppression de la boutique est irréversible. Toutes les données (produits, ventes, employés) seront définitivement perdues.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _confirmDelete(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Supprimer la boutique'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Sticky save bar ───────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer les modifications',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la boutique ?'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.\n\nContactez le support Scalario pour procéder à la suppression.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController ctrl,
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    const radius = BorderRadius.all(Radius.circular(10));
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
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
            borderSide:
                BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}

// ── Shared atoms ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label : ',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
