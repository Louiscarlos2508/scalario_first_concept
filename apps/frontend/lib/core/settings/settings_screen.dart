import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/providers/active_modules_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/business_type/utils/role_label_utils.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:frontend/features/retail/pos/presentation/screens/team_pin_screen.dart';
import 'package:frontend/core/printing/printer_setup_sheet.dart';
import 'package:frontend/features/shared/team/presentation/screens/team_screen.dart';
import 'package:frontend/features/shared/billing/presentation/screens/subscription_screen.dart';
import 'package:frontend/features/shared/settings/presentation/screens/general_settings_screen.dart';
import 'package:frontend/features/shared/settings/presentation/screens/integrations_settings_screen.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────────
const _kReceiptHeader = 'settings_receipt_header';
const _kReceiptFooter = 'settings_receipt_footer';

// ── Full module catalogue (code → label) ─────────────────────────────────────
const _kAllModules = [
  ('catalog', 'Catalogue'),
  ('clients', 'Clients'),
  ('inventory', 'Inventaire & Stock'),
  ('transactions', 'Transactions & Ventes'),
  ('expenses', 'Dépenses & Charges'),
  ('reports', 'Rapports & KPI'),
  ('retail', 'Point de Vente (POS)'),
  ('variants', 'Variantes Produit'),
  ('pricing', 'Multi-Tarifs'),
  ('promotions', 'Promotions & Remises'),
  ('purchase_orders', 'Achats'),
  ('batches', 'Lots & Fraîcheur'),
  ('client_orders', 'Commandes Clients'),
];

// ── Helper ────────────────────────────────────────────────────────────────────
String _token() {
  try {
    return Supabase.instance.client.auth.currentSession?.accessToken ?? '';
  } catch (_) {
    return '';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Last products sync timestamp (reads from Isar SyncMetadata).
final lastSyncProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  return isarService.getLastSync('products');
});

/// Tenant public info (name, address, phone, businessType, currency).
final tenantInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};
  final token = _token();
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant/my-info'),
    headers: ApiConstants.headers(tenantId: tenantId, token: token),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  return {};
});

/// Billing info for the current tenant (owner-facing).
final tenantBillingProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};
  final token = _token();
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/settings/billing'),
    headers: ApiConstants.headers(tenantId: tenantId, token: token),
  );
  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  return {};
});

/// Users list for the current tenant (owner-facing).
final tenantUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  final token = _token();
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant/my-users'),
    headers: ApiConstants.headers(tenantId: tenantId, token: token),
  );
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as List;
    return body.cast<Map<String, dynamic>>();
  }
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _tenantInfoLoaded = false;

  // Receipt section controllers (local prefs only)
  final _receiptHeaderCtrl = TextEditingController();
  final _receiptFooterCtrl = TextEditingController();

  // Freshness thresholds (FR84)
  final _greenThresholdCtrl = TextEditingController();
  final _orangeThresholdCtrl = TextEditingController();
  bool _savingFreshness = false;

  // Daily summary notifications (FR86)
  bool _dailySummaryEnabled = false;
  final _dailySummaryTimeCtrl = TextEditingController(text: '18:00');
  bool _savingNotification = false;

  // Return policy (FR98)
  final _returnPolicyDaysCtrl = TextEditingController();
  bool _requiresReason = true;
  bool _requiresApproval = false;
  bool _savingReturnPolicy = false;

  // Session lock timeout (minutes; -1 = disabled)
  int _lockTimeout = 10;

  @override
  void initState() {
    super.initState();
    _loadReceiptPrefs();
    _receiptHeaderCtrl.addListener(() => setState(() {}));
    _receiptFooterCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _receiptHeaderCtrl.dispose();
    _receiptFooterCtrl.dispose();
    _greenThresholdCtrl.dispose();
    _orangeThresholdCtrl.dispose();
    _dailySummaryTimeCtrl.dispose();
    _returnPolicyDaysCtrl.dispose();
    super.dispose();
  }

  // ── Init helpers ────────────────────────────────────────────────────────────

  void _fillTenantInfoOnce(Map<String, dynamic> info) {
    if (_tenantInfoLoaded) return;
    _tenantInfoLoaded = true;
    // Freshness thresholds (FR84)
    _greenThresholdCtrl.text = (info['freshnessGreenThreshold'] ?? 50).toString();
    _orangeThresholdCtrl.text = (info['freshnessOrangeThreshold'] ?? 20).toString();
    // Daily summary (FR86)
    _dailySummaryTimeCtrl.text = info['dailySummaryTime'] as String? ?? '18:00';
    // Return policy (FR98)
    _returnPolicyDaysCtrl.text = (info['returnPolicyDays'] ?? 30).toString();
    setState(() {
      _dailySummaryEnabled = info['dailySummaryEnabled'] as bool? ?? false;
      _requiresReason = info['returnRequiresReason'] as bool? ?? true;
      _requiresApproval = info['returnRequiresApproval'] as bool? ?? false;
    });
  }

  Future<void> _loadReceiptPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _receiptHeaderCtrl.text = prefs.getString(_kReceiptHeader) ?? '';
      _receiptFooterCtrl.text = prefs.getString(_kReceiptFooter) ?? '';
      _lockTimeout = prefs.getInt(kLockTimeoutPrefKey) ?? 10;
    });
    // Sync provider with persisted value
    ref.read(sessionLockTimeoutProvider.notifier).state = _lockTimeout;
  }

  Future<void> _saveLockTimeout(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kLockTimeoutPrefKey, minutes);
    if (!mounted) return;
    setState(() => _lockTimeout = minutes);
    ref.read(sessionLockTimeoutProvider.notifier).state = minutes;
  }

  // ── Save actions ────────────────────────────────────────────────────────────

  Future<void> _saveReceiptPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReceiptHeader, _receiptHeaderCtrl.text.trim());
    await prefs.setString(_kReceiptFooter, _receiptFooterCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration reçu sauvegardée')),
    );
  }

  Future<void> _saveFreshnessThresholds() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _savingFreshness = true);
    try {
      final green = int.tryParse(_greenThresholdCtrl.text.trim()) ?? 50;
      final orange = int.tryParse(_orangeThresholdCtrl.text.trim()) ?? 20;
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/organizations/freshness-thresholds'),
        headers: ApiConstants.headers(tenantId: tenantId, token: _token()),
        body: jsonEncode({'greenThreshold': green, 'orangeThreshold': orange}),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(tenantInfoProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seuils de fraîcheur enregistrés')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _savingFreshness = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _savingNotification = true);
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/organizations/notification-settings'),
        headers: ApiConstants.headers(tenantId: tenantId, token: _token()),
        body: jsonEncode({
          'dailySummaryEnabled': _dailySummaryEnabled,
          'dailySummaryTime': _dailySummaryTimeCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(tenantInfoProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications enregistrées')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _savingNotification = false);
    }
  }

  Future<void> _saveReturnPolicy() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _savingReturnPolicy = true);
    try {
      final days = int.tryParse(_returnPolicyDaysCtrl.text.trim()) ?? 30;
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/organizations/return-policy'),
        headers: ApiConstants.headers(tenantId: tenantId, token: _token()),
        body: jsonEncode({
          'returnPolicyDays': days,
          'returnRequiresReason': _requiresReason,
          'returnRequiresApproval': _requiresApproval,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(tenantInfoProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Politique retours enregistrée')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${response.statusCode}'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _savingReturnPolicy = false);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  Future<void> _confirmClearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vider le cache local'),
        content: const Text(
          'Toutes les données locales seront supprimées. '
          "Redémarrez l'application pour recharger les données.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final isarService = ref.read(isarServiceProvider);
      final isar = await isarService.db;
      await isar.writeTxn(() => isar.clear());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cache vidé. Redémarrez l'application pour recharger les données.",
          ),
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final activeTenantId = ref.watch(activeTenantProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final outboxCount = ref.watch(inventoryOutboxCountProvider);
    final lastSync = ref.watch(lastSyncProvider);
    final tenantInfo = ref.watch(tenantInfoProvider);
    final activeModules = ref.watch(activeModulesProvider);
    final roleLabels =
        ref.watch(businessTypeConfigProvider).valueOrNull?.roleLabels ?? {};

    // Role detection
    final profile = userProfileAsync.valueOrNull;
    final activeMembership = profile == null || profile.memberships.isEmpty
        ? null
        : profile.memberships.cast<TenantMembership?>().firstWhere(
            (m) => m?.tenantId == activeTenantId,
            orElse: () => profile.memberships.first,
          );
    final role = activeMembership?.role ?? '';
    final isOwner   = role == 'owner';
    final isManager = role == 'manager';
    final roleLabel = getRoleLabel(role, roleLabels);

    // Pre-fill boutique controllers from API data (once)
    tenantInfo.whenData(_fillTenantInfoOnce);

    final tenantName = tenantInfo.valueOrNull?['name'] as String? ??
        activeMembership?.tenantName ??
        '';

    return Scaffold(
      appBar: const ScalarioAppBar(title: 'Paramètres'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Compte ────────────────────────────────────────────────────
            _section('Compte', [
              _infoRow(
                'Email',
                userProfileAsync.when(
                  data: (p) => p?.email ?? '—',
                  loading: () => '…',
                  error: (_, _) => '—',
                ),
              ),
              _infoRow('Rôle', roleLabel),
              _infoRow('Boutique', tenantName.isNotEmpty ? tenantName : '—'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: _confirmLogout,
                ),
              ),
            ]),

            // ── 2. Liens vers écrans dédiés (owner) ──────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _section('Boutique & Configuration', [
                _navTile(
                  context,
                  icon: Icons.store_outlined,
                  title: 'Paramètres généraux',
                  subtitle: 'Nom, adresse, devise, zone dangereuse',
                  screen: const GeneralSettingsScreen(),
                ),
                const Divider(height: 20),
                _navTile(
                  context,
                  icon: Icons.people_outline,
                  title: 'Équipe & Utilisateurs',
                  subtitle: 'Rôles, accès, invitations',
                  screen: const TeamScreen(),
                ),
                const Divider(height: 20),
                _navTile(
                  context,
                  icon: Icons.credit_card_outlined,
                  title: 'Mon abonnement',
                  subtitle: 'Plan, facturation, historique',
                  screen: const SubscriptionScreen(),
                ),
                const Divider(height: 20),
                _navTile(
                  context,
                  icon: Icons.link_outlined,
                  title: 'Intégrations',
                  subtitle: 'Orange Money, Moov Money, API',
                  screen: const IntegrationsSettingsScreen(),
                ),
              ]),
            ],

            if (isManager) ...[
              const SizedBox(height: 16),
              _section('Boutique', [
                _navTile(
                  context,
                  icon: Icons.people_outline,
                  title: 'Équipe',
                  subtitle: 'Voir les membres de l\'équipe',
                  screen: const TeamScreen(),
                ),
              ]),
            ],

            // ── 3. Caissiers & PINs ───────────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildTeamPinSection(context),
            ],

            // ── 4. Sécurité ───────────────────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildSecuritySection(),
            ],

            // ── 5. Fraîcheur ──────────────────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildFreshnessSection(),
            ],

            // ── 6. Récapitulatif journalier ───────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildNotificationSection(),
            ],

            // ── 7. Politique de retours ───────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildReturnPolicySection(),
            ],

            // ── 8. Modules actifs ─────────────────────────────────────────────
            if (isOwner || isManager) ...[
              const SizedBox(height: 16),
              _buildModulesSection(activeModules),
            ],

            // ── 9. Méthodes de paiement ───────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildPaymentMethodsSection(),
            ],

            // ── 10. Reçu ─────────────────────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildReceiptSection(),
            ],

            // ── 11. Imprimante ────────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildPrinterSection(),

            // ── 12. Synchronisation ───────────────────────────────────────────
            const SizedBox(height: 16),
            _buildSyncSection(syncStatus, outboxCount, lastSync),

            // ── 13. Application ───────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildAppSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildFreshnessSection() {
    return _section('Seuils de fraîcheur (Lots)', [
      const Text(
        'Définissez les seuils de stock pour les alertes de fraîcheur.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 12),
      _field(
        controller: _greenThresholdCtrl,
        label: 'Seuil vert (unités)',
        hint: '50',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      _field(
        controller: _orangeThresholdCtrl,
        label: 'Seuil orange (unités)',
        hint: '20',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: _savingFreshness ? null : _saveFreshnessThresholds,
          child: _savingFreshness
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ),
    ]);
  }

  Widget _buildNotificationSection() {
    return _section('Récapitulatif journalier', [
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Activer le récapitulatif quotidien'),
        value: _dailySummaryEnabled,
        onChanged: (v) => setState(() => _dailySummaryEnabled = v),
      ),
      if (_dailySummaryEnabled) ...[
        const SizedBox(height: 8),
        _field(
          controller: _dailySummaryTimeCtrl,
          label: "Heure d'envoi (HH:mm)",
          hint: '18:00',
        ),
      ],
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: _savingNotification ? null : _saveNotificationSettings,
          child: _savingNotification
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ),
    ]);
  }

  Widget _buildReturnPolicySection() {
    return _section('Politique de retours', [
      _field(
        controller: _returnPolicyDaysCtrl,
        label: 'Délai de retour (jours)',
        hint: '30',
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Motif obligatoire'),
        value: _requiresReason,
        onChanged: (v) => setState(() => _requiresReason = v),
      ),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Approbation requise'),
        value: _requiresApproval,
        onChanged: (v) => setState(() => _requiresApproval = v),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: _savingReturnPolicy ? null : _saveReturnPolicy,
          child: _savingReturnPolicy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ),
    ]);
  }

  Widget _buildTeamPinSection(BuildContext context) {
    return _section('Caissiers & PINs', [
      const Text(
        'Gérez les profils PIN des employés qui partagent ce terminal de caisse.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: 18,
          child: Icon(Icons.badge_outlined, color: Colors.white, size: 18),
        ),
        title: const Text('Gérer les caissiers',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Ajouter, modifier ou supprimer des profils PIN'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TeamPinScreen()),
        ),
      ),
    ]);
  }

  Widget _buildSecuritySection() {
    const options = [
      (-1, 'Désactivé'),
      (5, '5 minutes'),
      (10, '10 minutes'),
      (30, '30 minutes'),
    ];
    return _section('Sécurité', [
      const Text(
        'Durée d\'inactivité avant verrouillage automatique de la caisse.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 8),
      ...options.map((opt) {
        final (value, label) = opt;
        return RadioListTile<int>(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label),
          value: value,
          groupValue: _lockTimeout,
          onChanged: (v) { if (v != null) _saveLockTimeout(v); },
        );
      }),
    ]);
  }

  Widget _buildModulesSection(AsyncValue<Set<String>> activeModulesAsync) {
    return _section('Modules actifs', [
      activeModulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const SizedBox.shrink(),
        data: (activeSet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._kAllModules.map((entry) {
              final (code, label) = entry;
              final isActive = activeSet.contains(code);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      isActive ? Icons.check_circle : Icons.cancel_outlined,
                      size: 16,
                      color: isActive ? Colors.green : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color:
                              isActive ? null : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (!isActive)
                      Text(
                        'non inclus',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Pour activer plus de modules, contactez votre administrateur.',
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPaymentMethodsSection() {
    final enabledAsync = ref.watch(enabledPaymentMethodsProvider);
    final enabled = enabledAsync.valueOrNull ?? kDefaultPaymentMethods;
    final tenantId = ref.read(activeTenantProvider);

    Future<void> save(List<PaymentMethod> next) async {
      if (!next.any((m) => m.code == 'CASH')) return; // CASH mandatory
      try {
        final response = await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/tenant/my-info'),
          headers: ApiConstants.headers(tenantId: tenantId, token: _token()),
          body: jsonEncode({
            'paymentMethods': next.map((m) => m.toJson()).toList()
          }),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          ref.invalidate(enabledPaymentMethodsProvider);
        }
      } catch (_) {}
    }

    void toggle(PaymentMethod method, bool currentlyOn) {
      final next = currentlyOn
          ? enabled.where((m) => m.code != method.code).toList()
          : [...enabled, method];
      save(next);
    }

    void addCustom(String label) {
      final code = label
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '_');
      if (enabled.any((m) => m.code == code)) return;
      save([...enabled, PaymentMethod(code, label.trim())]);
    }

    void removeCustom(String code) {
      save(enabled.where((m) => m.code != code).toList());
    }

    final customMethods =
        enabled.where((m) => !kBuiltinCodes.contains(m.code)).toList();

    return _section('Méthodes de paiement', [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Espèces est toujours activé. Activez les autres selon vos besoins.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),

      // ── Built-in toggles ─────────────────────────────────────────────
      ...kBuiltinPaymentMethods.map((method) {
        final isCash = method.code == 'CASH';
        final isOn = enabled.any((m) => m.code == method.code);
        return SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(method.label),
          value: isOn,
          onChanged: isCash ? null : (_) => toggle(method, isOn),
        );
      }),

      const Divider(height: 24),

      // ── Custom methods ───────────────────────────────────────────────
      Row(
        children: [
          const Text('Méthodes personnalisées',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Ajouter'),
            onPressed: () async {
              final ctrl = TextEditingController();
              final label = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Nouvelle méthode'),
                  content: TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nom (ex: Orange Money, Wave…)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (v) =>
                        Navigator.pop(context, v.trim()),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler')),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, ctrl.text.trim()),
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
              );
              ctrl.dispose();
              if (label != null && label.isNotEmpty) addCustom(label);
            },
          ),
        ],
      ),
      if (customMethods.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Aucune méthode personnalisée',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ...customMethods.map((m) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.payment_outlined, size: 20),
            title: Text(m.label),
            subtitle: Text(m.code,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              tooltip: 'Supprimer',
              onPressed: () => removeCustom(m.code),
            ),
          )),
    ]);
  }

  Widget _buildReceiptSection() {
    return _section('Reçu', [
      _field(
        controller: _receiptHeaderCtrl,
        label: 'En-tête du reçu',
        hint: 'Ma Boutique',
      ),
      const SizedBox(height: 12),
      _field(
        controller: _receiptFooterCtrl,
        label: 'Pied de page',
        hint: 'Merci de votre visite !',
      ),
      const SizedBox(height: 16),
      const Text('Aperçu', style: AppTextStyles.labelSmall),
      const SizedBox(height: 8),
      _receiptPreview(),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton(
          onPressed: _saveReceiptPrefs,
          child: const Text('Sauvegarder'),
        ),
      ),
    ]);
  }

  Widget _buildPrinterSection() {
    return _section('Imprimante', [const PrinterSetupContent()]);
  }

  Widget _buildSyncSection(
    AsyncValue<SyncUiStatus> syncStatus,
    AsyncValue<int> outboxCount,
    AsyncValue<DateTime?> lastSync,
  ) {
    final status = syncStatus.when(
      data: (s) => s,
      loading: () => SyncUiStatus.disconnected,
      error: (_, _) => SyncUiStatus.error,
    );
    return _section('Synchronisation', [
      _infoRow(
        'Statut',
        _syncLabel(status),
      ),
      _infoRow(
        'En attente',
        outboxCount.when(
          data: (n) => '$n mutation${n > 1 ? 's' : ''}',
          loading: () => '…',
          error: (_, _) => '—',
        ),
      ),
      _infoRow(
        'Dernière sync',
        lastSync.when(
          data: (dt) => dt != null
              ? DateFormat('dd/MM/yyyy HH:mm').format(dt)
              : 'Jamais',
          loading: () => '…',
          error: (_, _) => '—',
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.sync),
          label: const Text('Forcer la synchronisation'),
          onPressed: () {
            ref.read(syncServiceProvider).forceSync();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Synchronisation déclenchée')),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildAppSection() {
    return _section('Application', [
      _infoRow('Version', 'Scalario v1.0.0'),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Vider le cache local'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: _confirmClearCache,
        ),
      ),
    ]);
  }

  // ── Shared builders ────────────────────────────────────────────────────────

  Widget _navTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textSecondary),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.titleMedium),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label :', style: AppTextStyles.bodySmall),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _receiptPreview() {
    final header = _receiptHeaderCtrl.text.trim().isNotEmpty
        ? _receiptHeaderCtrl.text.trim()
        : 'Ma Boutique';
    final footer = _receiptFooterCtrl.text.trim().isNotEmpty
        ? _receiptFooterCtrl.text.trim()
        : 'Merci de votre visite !';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              header,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Article exemple', style: AppTextStyles.bodySmall),
              Text('1 000 FCFA', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '1 000 FCFA',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 12),
          Center(
            child: Text(
              footer,
              style: AppTextStyles.bodySmall
                  .copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _syncLabel(SyncUiStatus status) {
    switch (status) {
      case SyncUiStatus.connected:
        return 'Connecté';
      case SyncUiStatus.syncing:
        return 'En cours…';
      case SyncUiStatus.error:
        return 'Erreur';
      case SyncUiStatus.disconnected:
        return 'Déconnecté';
    }
  }

}

