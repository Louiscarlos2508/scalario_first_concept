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
import 'package:frontend/features/shared/inventory/presentation/providers/loss_locations_provider.dart';

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
    _shopNameCtrl.text = info['name'] as String? ?? '';
    _shopAddressCtrl.text = info['address'] as String? ?? '';
    _shopPhoneCtrl.text = info['phone'] as String? ?? '';
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

  Future<void> _showInviteDialog(String tenantId) async {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'commercial';
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Inviter un membre'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nom complet (optionnel)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(
                      value: 'commercial', child: Text('Commercial')),
                ],
                onChanged: (v) =>
                    setDialogState(() => selectedRole = v ?? selectedRole),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      setDialogState(() => sending = true);
                      try {
                        final body = <String, dynamic>{
                          'email': email,
                          'role': selectedRole,
                        };
                        if (nameCtrl.text.trim().isNotEmpty) {
                          body['fullName'] = nameCtrl.text.trim();
                        }
                        final response = await http.post(
                          Uri.parse(
                              '${ApiConstants.baseUrl}/organizations/$tenantId/invite'),
                          headers: ApiConstants.headers(
                              tenantId: tenantId, token: _token()),
                          body: jsonEncode(body),
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (response.statusCode == 200 ||
                            response.statusCode == 201) {
                          ref.invalidate(tenantUsersProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Invitation envoyée')),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Erreur : ${response.statusCode}'),
                              backgroundColor: AppColors.error,
                            ));
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erreur : $e'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      }
                    },
              child: const Text('Inviter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeRoleDialog(
      String tenantId, String userId, String currentRole) async {
    String selectedRole =
        currentRole == 'owner' ? 'manager' : currentRole;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Changer le rôle'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Nouveau rôle'),
            items: const [
              DropdownMenuItem(value: 'manager', child: Text('Manager')),
              DropdownMenuItem(
                  value: 'commercial', child: Text('Commercial')),
            ],
            onChanged: (v) =>
                setDialogState(() => selectedRole = v ?? selectedRole),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        final response = await http.patch(
                          Uri.parse(
                              '${ApiConstants.baseUrl}/organizations/$tenantId/members/$userId'),
                          headers: ApiConstants.headers(
                              tenantId: tenantId, token: _token()),
                          body: jsonEncode({'role': selectedRole}),
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        if (response.statusCode == 200 ||
                            response.statusCode == 204) {
                          ref.invalidate(tenantUsersProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Rôle mis à jour')),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Erreur : ${response.statusCode}'),
                              backgroundColor: AppColors.error,
                            ));
                          }
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erreur : $e'),
                            backgroundColor: AppColors.error,
                          ));
                        }
                      }
                    },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
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
            if (isOwner || isManager) ...[
              const SizedBox(height: 16),
              _buildBoutiqueSection(isOwner, tenantInfo),
            ],

            // ── 3b. Type de commerce (owner : lecture seule) ─────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildBusinessTypeSection(tenantInfo),
            ],

            // ── 3c. Équipe (manager : lecture seule) ─────────────────────────
            if (isManager) ...[
              const SizedBox(height: 16),
              _buildTeamSection(roleLabels),
            ],

            // ── 4. Utilisateurs (owner seulement) ────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildUsersSection(roleLabels),
            ],

            // ── 4b. Fraîcheur (owner seulement) ──────────────────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildFreshnessSection(),
            ],

            // ── 4c. Récapitulatif journalier (owner seulement) ────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildNotificationSection(),
            ],

            // ── 4d. Politique de retours (owner seulement) ───────────────────
            if (isOwner) ...[
              const SizedBox(height: 16),
              _buildReturnPolicySection(),
            ],

            // ── 5. Modules actifs (owner + manager) ──────────────────────────
            if (isOwner || isManager) ...[
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
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 4),
        _LossLocationsEditor(),
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
    final tenantId = ref.read(activeTenantProvider) ?? '';
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
          return Column(
            children: [
              if (users.isEmpty)
                Text(
                  'Aucun utilisateur trouvé.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ...users.map((u) {
                final email = u['email'] as String? ?? '—';
                final fullName = u['fullName'] as String?;
                final userId = u['userId'] as String? ?? '';
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
                      if (userRole != 'owner')
                        PopupMenuButton<String>(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          tooltip: 'Actions',
                          onSelected: (action) {
                            if (action == 'change_role') {
                              _showChangeRoleDialog(tenantId, userId, userRole);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'change_role',
                              child: Text('Changer le rôle'),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Inviter un membre'),
                  onPressed: () => _showInviteDialog(tenantId),
                ),
              ),
            ],
          );
        },
      ),
    ]);
  }

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

  Widget _buildTeamSection(Map<String, dynamic> roleLabels) {
    final usersAsync = ref.watch(tenantUsersProvider);
    return _section('Équipe', [
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
              'Aucun membre.',
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

  Widget _buildBusinessTypeSection(
      AsyncValue<Map<String, dynamic>> tenantInfo) {
    final config = ref.watch(businessTypeConfigProvider).valueOrNull;
    final info = tenantInfo.valueOrNull ?? {};
    final btName = config?.name ??
        info['businessTypeName'] as String? ??
        '—';
    final btCode =
        config?.code ?? info['businessType'] as String? ?? '—';

    return _section('Type de commerce', [
      _infoRow('Type', btName),
      _infoRow('Code', btCode),
      const SizedBox(height: 8),
      Text(
        'Pour changer le type de commerce, contactez votre administrateur.',
        style: AppTextStyles.bodySmall.copyWith(
          fontStyle: FontStyle.italic,
          color: AppColors.textSecondary,
        ),
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

// ── FR87 — Éditeur d'emplacements de perte (owner seulement) ─────────────────

class _LossLocationsEditor extends ConsumerStatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  _LossLocationsEditor();

  @override
  ConsumerState<_LossLocationsEditor> createState() =>
      _LossLocationsEditorState();
}

class _LossLocationsEditorState extends ConsumerState<_LossLocationsEditor> {
  final _newLocCtrl = TextEditingController();
  bool _saving = false;

  static const _suggestedDefaults = ['Magasin', 'Rayon', 'Transit', 'Stockroom'];

  @override
  void dispose() {
    _newLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _patch(List<String> locations) async {
    setState(() => _saving = true);
    try {
      final tenantId = ref.read(activeTenantProvider);
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/tenant/loss-locations'),
        headers: ApiConstants.headers(tenantId: tenantId, token: _token()),
        body: jsonEncode({'locations': locations}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        ref.invalidate(lossLocationsProvider);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add(List<String> current) {
    final val = _newLocCtrl.text.trim();
    if (val.isEmpty || current.contains(val)) return;
    _newLocCtrl.clear();
    _patch([...current, val]);
  }

  void _remove(List<String> current, String loc) {
    _patch(current.where((l) => l != loc).toList());
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(lossLocationsProvider).valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Emplacements de perte', style: AppTextStyles.labelSmall),
        const SizedBox(height: 4),
        const Text(
          'Optionnel. Si configurés, le champ devient obligatoire lors d\'une déclaration de perte.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (locations.isEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _suggestedDefaults
                .map((d) => ActionChip(
                      label: Text(d),
                      avatar: const Icon(Icons.add, size: 16),
                      onPressed: _saving ? null : () => _patch(_suggestedDefaults),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          const Text(
            'Appuyez sur une suggestion pour charger tous les défauts.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ] else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: locations
                .map((loc) => Chip(
                      label: Text(loc),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: _saving ? null : () => _remove(locations, loc),
                    ))
                .toList(),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newLocCtrl,
                decoration: const InputDecoration(
                  hintText: 'Nouvel emplacement...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(locations),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              height: 40,
              child: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _add(locations),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
