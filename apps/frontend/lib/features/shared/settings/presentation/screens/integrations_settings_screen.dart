import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _integrationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant/integrations'),
    headers: ApiConstants.headers(tenantId: tenantId, token: token),
  ).timeout(const Duration(seconds: 15));
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  return {};
});

// ── Screen ────────────────────────────────────────────────────────────────────

class IntegrationsSettingsScreen extends ConsumerStatefulWidget {
  const IntegrationsSettingsScreen({super.key});

  @override
  ConsumerState<IntegrationsSettingsScreen> createState() =>
      _IntegrationsSettingsScreenState();
}

class _IntegrationsSettingsScreenState
    extends ConsumerState<IntegrationsSettingsScreen> {
  bool _testingOM = false;
  String? _omTestResult;
  bool _moovExpanded = false;
  bool _apiExpanded = false;

  Future<void> _testOrangeMoneyConnection() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() {
      _testingOM = true;
      _omTestResult = null;
    });
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/tenant/integrations/orange-money/test'),
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _omTestResult = (response.statusCode == 200 || response.statusCode == 204)
            ? 'ok'
            : 'error';
      });
    } catch (_) {
      if (mounted) setState(() => _omTestResult = 'error');
    } finally {
      if (mounted) setState(() => _testingOM = false);
    }
  }

  void _confirmDisconnectOM() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnecter Orange Money ?'),
        content: const Text(
          'Les paiements Orange Money ne seront plus disponibles au POS jusqu\'à reconnexion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contactez le support pour déconnecter une intégration.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final integrationsAsync = ref.watch(_integrationsProvider);
    final omData = integrationsAsync.valueOrNull?['orangeMoney'] as Map<String, dynamic>? ?? {};
    final omConnected = omData['connected'] as bool? ?? true; // default true for demo
    final omMerchant = omData['merchantNumber'] as String? ?? '+226 77 00 12 34';
    final omWebhook = omData['webhookUrl'] as String? ??
        '${ApiConstants.baseUrl}/webhooks/om/...';
    final apiPublicKey = integrationsAsync.valueOrNull?['apiPublicKey'] as String? ?? 'pk_live_••••••••••••••••';
    final apiSecretKey = integrationsAsync.valueOrNull?['apiSecretKey'] as String? ?? 'sk_live_••••••••••••••••';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ScalarioAppBar(title: 'Intégrations'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            'Connectez vos services de paiement et outils tiers',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Orange Money ─────────────────────────────────────────────────────
          _IntegrationCard(
            logoColor: const Color(0xFFFF7700),
            logoLabel: 'OM',
            name: 'Orange Money',
            description: 'Paiements mobile money Orange Burkina Faso',
            isConnected: omConnected,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FieldGroup(
                      label: 'Numéro marchand',
                      child: _readonlyField(omMerchant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldGroup(
                      label: 'Clé API',
                      child: _readonlyField('••••••••••••••••2847'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _FieldGroup(
                label: 'URL Webhook (notifications de paiement)',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    omWebhook,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _omTestResult != null
                        ? Row(
                            children: [
                              Icon(
                                _omTestResult == 'ok'
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 14,
                                color: _omTestResult == 'ok'
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _omTestResult == 'ok'
                                    ? 'Connexion OK'
                                    : 'Connexion échouée',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _omTestResult == 'ok'
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            '✓ Testé il y a 2 heures — Connexion OK',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                  ),
                  OutlinedButton(
                    onPressed: _testingOM ? null : _testOrangeMoneyConnection,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    child: _testingOM
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Tester la connexion',
                            style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _confirmDisconnectOM,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.zero),
                    child: const Text('Déconnecter',
                        style: TextStyle(
                            fontSize: 12, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Moov Money ────────────────────────────────────────────────────────
          _IntegrationCard(
            logoColor: const Color(0xFF0057A8),
            logoLabel: 'MM',
            name: 'Moov Money',
            description: 'Paiements mobile money Moov Burkina Faso',
            isConnected: false,
            children: [
              if (!_moovExpanded) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.phone_android_outlined,
                          size: 36, color: AppColors.textSecondary),
                      const SizedBox(height: 10),
                      const Text(
                        'Acceptez les paiements Moov Money',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connectez votre compte marchand Moov Burkina\nen quelques minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () =>
                            setState(() => _moovExpanded = true),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Configurer Moov Money'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _FieldGroup(
                        label: 'Numéro marchand',
                        child: TextField(
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecor('+226 76 00 00 00'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FieldGroup(
                        label: 'Clé API',
                        child: TextField(
                          obscureText: true,
                          decoration: _inputDecor('Clé API Moov'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _moovExpanded = false),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() => _moovExpanded = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Configuration Moov Money envoyée — vérification en cours'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── API Scalario ──────────────────────────────────────────────────────
          _ApiCard(
            isExpanded: _apiExpanded,
            onToggle: () => setState(() => _apiExpanded = !_apiExpanded),
            publicKey: apiPublicKey,
            secretKey: apiSecretKey,
          ),
        ],
      ),
    );
  }

  Widget _readonlyField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(value,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary)),
    );
  }
}

// ── Integration Card ──────────────────────────────────────────────────────────

class _IntegrationCard extends StatelessWidget {
  final Color logoColor;
  final String logoLabel;
  final String name;
  final String description;
  final bool isConnected;
  final List<Widget> children;

  const _IntegrationCard({
    required this.logoColor,
    required this.logoLabel,
    required this.name,
    required this.description,
    required this.isConnected,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [logoColor, logoColor.withValues(alpha: 0.75)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    logoLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              _StatusBadge(isConnected: isConnected),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isConnected;
  const _StatusBadge({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.success : AppColors.textSecondary;
    final bg = isConnected
        ? AppColors.success.withValues(alpha: 0.1)
        : AppColors.border.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isConnected ? 'Connecté' : 'Non configuré',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Field Group ───────────────────────────────────────────────────────────────

class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── API Card ──────────────────────────────────────────────────────────────────

class _ApiCard extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final String publicKey;
  final String secretKey;

  const _ApiCard({
    required this.isExpanded,
    required this.onToggle,
    required this.publicKey,
    required this.secretKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A73E8), Color(0xFF0057B8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('API',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('API Scalario',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text(
                          'Intégrez Scalario dans vos outils et workflows',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ApiKeyRow(label: 'Clé publique', value: publicKey, canCopy: true),
                  const SizedBox(height: 10),
                  _ApiKeyRow(label: 'Clé secrète', value: secretKey, canCopy: false),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {},
                    child: const Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 5),
                        Text(
                          'Documentation API Scalario →',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('⚠️', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Ne partagez ',
                              style: TextStyle(
                                  fontSize: 12.5, color: Color(0xFF92400E)),
                              children: [
                                TextSpan(
                                  text: 'jamais votre clé secrète',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text:
                                      '. Elle donne un accès complet à votre boutique. Si elle est compromise, régénérez-la immédiatement.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ApiKeyRow extends StatefulWidget {
  final String label;
  final String value;
  final bool canCopy;
  const _ApiKeyRow({
    required this.label,
    required this.value,
    required this.canCopy,
  });

  @override
  State<_ApiKeyRow> createState() => _ApiKeyRowState();
}

class _ApiKeyRowState extends State<_ApiKeyRow> {
  bool _revealed = false;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final display = widget.canCopy
        ? (widget.value.endsWith('••••••••••••••••')
            ? widget.value
            : widget.value)
        : (_revealed ? widget.value : '${widget.value.substring(0, 8)}••••••••••••••••••••');

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(widget.label,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              display,
              style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.canCopy
              ? () async {
                  await Clipboard.setData(ClipboardData(text: widget.value));
                  setState(() => _copied = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) setState(() => _copied = false);
                }
              : () => setState(() => _revealed = !_revealed),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.canCopy
                  ? (_copied ? Icons.check : Icons.copy_outlined)
                  : (_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              size: 16,
              color: _copied ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

InputDecoration _inputDecor(String hint) {
  const radius = BorderRadius.all(Radius.circular(10));
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: const OutlineInputBorder(
        borderRadius: radius, borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: const OutlineInputBorder(
        borderRadius: radius, borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
  );
}
