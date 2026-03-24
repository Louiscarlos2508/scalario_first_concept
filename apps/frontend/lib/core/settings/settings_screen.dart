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
  // Boutique section controllers (pre-filled from API)
  final _shopNameCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  bool _tenantInfoLoaded = false;
  bool _savingInfo = false;

  // Receipt section controllers (local prefs only)
  final _receiptHeaderCtrl = TextEditingController();
  final _receiptFooterCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadReceiptPrefs();
    _receiptHeaderCtrl.addListener(() => setState(() {}));
    _receiptFooterCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _shopPhoneCtrl.dispose();
    _shopAddressCtrl.dispose();
    _receiptHeaderCtrl.dispose();
    _receiptFooterCtrl.dispose();
    super.dispose();
  }

  // ── Init helpers ────────────────────────────────────────────────────────────

  void _fillTenantInfoOnce(Map<String, dynamic> info) {
    if (_tenantInfoLoaded) return;
    _tenantInfoLoaded = true;
    _shopNameCtrl.text = info['name'] as String? ?? '';
    _shopAddressCtrl.text = info['address'] as String? ?? '';
    _shopPhoneCtrl.text = info['phone'] as String? ?? '';
  }

  Future<void> _loadReceiptPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _receiptHeaderCtrl.text = prefs.getString(_kReceiptHeader) ?? '';
      _receiptFooterCtrl.text = prefs.getString(_kReceiptFooter) ?? '';
    });
  }

  // ── Save actions ────────────────────────────────────────────────────────────

  Future<void> _saveTenantInfo() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _savingInfo = true);
    try {
      final token = _token();
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tenant/my-info'),
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
        body: jsonEncode({
          'name': _shopNameCtrl.text.trim(),
          'address': _shopAddressCtrl.text.trim(),
          'phone': _shopPhoneCtrl.text.trim(),
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(tenantInfoProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informations boutique enregistrées')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${response.statusCode}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  Future<void> _saveReceiptPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReceiptHeader, _receiptHeaderCtrl.text.trim());
    await prefs.setString(_kReceiptFooter, _receiptFooterCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration reçu sauvegardée')),
    );
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
    final isOwner = role == 'owner';
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
            // ── 1. Compte (tous les rôles) ───────────────────────────────────
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

            // ── 2. Mon abonnement (owner seulement) ──────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildBillingSection(),
            ],

            // ── 3. Boutique ──────────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildBoutiqueSection(isOwner, tenantInfo),

            // ── 4. Utilisateurs (owner seulement) ────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildUsersSection(roleLabels),
            ],

            // ── 5. Modules actifs (owner seulement) ──────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildModulesSection(activeModules),
            ],

            // ── 6. Méthodes de paiement (owner seulement) ───────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildPaymentMethodsSection(),
            ],

            // ── 7. Reçu (owner seulement) ────────────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildReceiptSection(),
            ],

            // ── 7. Synchronisation (tous les rôles) ──────────────────────────
            const SizedBox(height: 16),
            _buildSyncSection(syncStatus, outboxCount, lastSync),

            // ── 8. Application (tous les rôles) ──────────────────────────────
            const SizedBox(height: 16),
            _buildAppSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  Widget _buildBillingSection() {
    final billingAsync = ref.watch(tenantBillingProvider);
    return _section('Mon abonnement', [
      billingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Text('Données indisponibles'),
        data: (billing) {
          final plan = billing['plan'] as Map<String, dynamic>? ?? {};
          final planName = plan['name'] as String? ?? billing['plan'] as String? ?? '—';
          final rawPrice = plan['monthlyPrice'];
          final priceNum = rawPrice is num
              ? rawPrice.toInt()
              : int.tryParse(rawPrice?.toString() ?? '') ?? 0;
          final priceStr =
              priceNum > 0 ? '${_formatNumber(priceNum)} FCFA/mois' : '';
          final billingStatus = billing['billingStatus'] as String? ?? 'trial';
          final trialEndsAt = _parseDate(billing['trialEndsAt']);
          final paidUntil = _parseDate(billing['paidUntil']);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(
                'Plan',
                priceStr.isNotEmpty ? '$planName ($priceStr)' : planName,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Statut : ', style: AppTextStyles.bodySmall),
                  const SizedBox(width: 4),
                  _billingBadge(billingStatus),
                ],
              ),
              const SizedBox(height: 8),
              _billingDateRow(billingStatus, trialEndsAt, paidUntil),
            ],
          );
        },
      ),
    ]);
  }

  Widget _buildBoutiqueSection(
    bool isOwner,
    AsyncValue<Map<String, dynamic>> tenantInfo,
  ) {
    final info = tenantInfo.valueOrNull ?? {};
    final businessTypeName = info['businessTypeName'] as String? ?? '—';
    final currency = info['currency'] as String? ?? 'XOF';

    if (isOwner) {
      return _section('Boutique', [
        _field(
          controller: _shopNameCtrl,
          label: 'Nom de la boutique',
          hint: 'Ma Boutique',
        ),
        const SizedBox(height: 12),
        _field(
          controller: _shopAddressCtrl,
          label: 'Adresse',
          hint: 'Ouaga, Secteur 30',
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        _field(
          controller: _shopPhoneCtrl,
          label: 'Téléphone',
          hint: '+226 70 00 00 00',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _infoRow('Type', businessTypeName),
        _infoRow('Devise', 'FCFA ($currency)'),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _savingInfo ? null : _saveTenantInfo,
            child: _savingInfo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer les modifications'),
          ),
        ),
      ]);
    }

    // Manager : lecture seule
    return _section('Boutique', [
      _infoRow('Nom', info['name'] as String? ?? '—'),
      _infoRow('Adresse', info['address'] as String? ?? '—'),
      _infoRow('Type', businessTypeName),
    ]);
  }

  Widget _buildUsersSection(Map<String, dynamic> roleLabels) {
    final usersAsync = ref.watch(tenantUsersProvider);
    return _section('Utilisateurs', [
      usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Text(
          'Données indisponibles',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        data: (users) {
          if (users.isEmpty) {
            return Text(
              'Aucun utilisateur trouvé.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            );
          }
          return Column(
            children: users.map((u) {
              final email = u['email'] as String? ?? '—';
              final fullName = u['fullName'] as String?;
              final userRole = u['role'] as String? ?? '';
              final label = getRoleLabel(userRole, roleLabels);
              final displayName = (fullName != null && fullName.isNotEmpty)
                  ? fullName
                  : email;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.person_outline,
                          size: 16, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: AppTextStyles.bodySmall),
                          if (fullName != null && fullName.isNotEmpty)
                            Text(
                              email,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      label,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
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

    Future<void> toggle(String code, bool currentlyOn) async {
      final next = currentlyOn
          ? enabled.where((m) => m != code).toList()
          : [...enabled, code];
      // CASH is mandatory — cannot be disabled
      if (!next.contains('CASH')) return;

      try {
        final token = _token();
        final response = await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/tenant/my-info'),
          headers: ApiConstants.headers(tenantId: tenantId, token: token),
          body: jsonEncode({'paymentMethods': next}),
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          ref.invalidate(enabledPaymentMethodsProvider);
        }
      } catch (_) {}
    }

    return _section('Méthodes de paiement', [
      const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Espèces est toujours activé. Activez les autres selon vos besoins.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      ...kAllPaymentMethods.map((entry) {
        final code = entry.$1;
        final label = entry.$2;
        final isCash = code == 'CASH';
        final isOn = enabled.contains(code);
        return SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: isOn,
          onChanged: isCash ? null : (_) => toggle(code, isOn),
        );
      }),
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

  Widget _billingBadge(String status) {
    final (label, color) = switch (status) {
      'trial' => ('Essai', Colors.blue),
      'active' => ('Actif', Colors.green),
      'overdue' => ('Impayé', Colors.orange),
      'suspended' => ('Suspendu', Colors.red),
      _ => (status, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _billingDateRow(
    String status,
    DateTime? trialEndsAt,
    DateTime? paidUntil,
  ) {
    final now = DateTime.now();
    String text;
    Color? color;

    if (status == 'trial' && trialEndsAt != null) {
      final days = trialEndsAt.difference(now).inDays;
      final dateStr = DateFormat('dd/MM/yyyy').format(trialEndsAt);
      if (days >= 0) {
        text = 'Essai jusqu\'au $dateStr ($days jours restants)';
      } else {
        text = 'Essai expiré — contactez votre administrateur';
        color = AppColors.error;
      }
    } else if (status == 'active' && paidUntil != null) {
      final days = paidUntil.difference(now).inDays;
      final dateStr = DateFormat('dd/MM/yyyy').format(paidUntil);
      text = 'Payé jusqu\'au $dateStr ($days jours restants)';
    } else if (status == 'overdue') {
      final expiredDays =
          paidUntil != null ? now.difference(paidUntil).inDays : null;
      text = expiredDays != null
          ? 'Expiré depuis $expiredDays jours — contactez votre administrateur'
          : 'Expiré — contactez votre administrateur';
      color = AppColors.error;
    } else {
      return const SizedBox.shrink();
    }

    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: color),
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

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw as String);
  }

  String _formatNumber(int n) {
    return NumberFormat('#,###', 'fr_FR').format(n).replaceAll(',', ' ');
  }
}
