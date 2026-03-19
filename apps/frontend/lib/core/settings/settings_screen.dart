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
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────────
const _kShopName = 'settings_shop_name';
const _kShopPhone = 'settings_shop_phone';
const _kShopAddress = 'settings_shop_address';
const _kReceiptHeader = 'settings_receipt_header';
const _kReceiptFooter = 'settings_receipt_footer';

/// Last products sync timestamp (reads from Isar SyncMetadata).
final lastSyncProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  final isarService = ref.watch(isarServiceProvider);
  return isarService.getLastSync('products');
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopNameCtrl = TextEditingController();
  final _shopPhoneCtrl = TextEditingController();
  final _shopAddressCtrl = TextEditingController();
  final _receiptHeaderCtrl = TextEditingController();
  final _receiptFooterCtrl = TextEditingController();

  // Notification settings
  bool _dailySummaryEnabled = false;
  String _dailySummaryTime = '18:00';
  String _notificationChannel = 'in_app';
  bool _savingNotif = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    // Rebuild receipt preview on each keystroke.
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

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _shopNameCtrl.text = prefs.getString(_kShopName) ?? '';
      _shopPhoneCtrl.text = prefs.getString(_kShopPhone) ?? '';
      _shopAddressCtrl.text = prefs.getString(_kShopAddress) ?? '';
      _receiptHeaderCtrl.text = prefs.getString(_kReceiptHeader) ?? '';
      _receiptFooterCtrl.text = prefs.getString(_kReceiptFooter) ?? '';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kShopName, _shopNameCtrl.text.trim());
    await prefs.setString(_kShopPhone, _shopPhoneCtrl.text.trim());
    await prefs.setString(_kShopAddress, _shopAddressCtrl.text.trim());
    await prefs.setString(_kReceiptHeader, _receiptHeaderCtrl.text.trim());
    await prefs.setString(_kReceiptFooter, _receiptFooterCtrl.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Paramètres sauvegardés')));
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

  Future<void> _saveNotificationSettings() async {
    final tenantId = ref.read(activeTenantProvider);
    if (tenantId == null) return;
    setState(() => _savingNotif = true);
    try {
      String? token;
      try {
        token = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {}
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/organizations/notification-settings'),
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
        body: jsonEncode({
          'dailySummaryEnabled': _dailySummaryEnabled,
          'dailySummaryTime': _dailySummaryTime,
          'notificationChannel': _notificationChannel,
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres notifications sauvegardés')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${response.statusCode}'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNotif = false);
    }
  }

  Future<void> _pickSummaryTime() async {
    final parts = _dailySummaryTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && mounted) {
      setState(() {
        _dailySummaryTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
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

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final activeTenantId = ref.watch(activeTenantProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final outboxCount = ref.watch(inventoryOutboxCountProvider);
    final lastSync = ref.watch(lastSyncProvider);

    final activeMembership = userProfileAsync.when(
      data: (profile) {
        if (profile == null || profile.memberships.isEmpty) return null;
        return profile.memberships.cast<TenantMembership?>().firstWhere(
              (m) => m?.tenantId == activeTenantId,
              orElse: () => profile.memberships.first,
            );
      },
      loading: () => null,
      error: (_, _) => null,
    );

    return Scaffold(
      appBar: const ScalarioAppBar(title: 'Paramètres'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // ── 1. Compte ─────────────────────────────────────────────────────
          _section('Compte', [
            _infoRow(
              'Email',
              userProfileAsync.when(
                data: (p) => p?.email ?? '—',
                loading: () => '…',
                error: (_, _) => '—',
              ),
            ),
            _infoRow('Rôle', _formatRole(activeMembership?.role)),
            _infoRow(
              'Tenant ID',
              activeTenantId != null
                  ? '${activeTenantId.substring(0, activeTenantId.length.clamp(0, 8))}…'
                  : '—',
            ),
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

          const SizedBox(height: 16),

          // ── 2. Boutique ───────────────────────────────────────────────────
          _section('Boutique', [
            _field(
              controller: _shopNameCtrl,
              label: 'Nom de la boutique',
              hint: 'Boutique Aminata',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _shopPhoneCtrl,
              label: 'Téléphone',
              hint: '+221 77 000 00 00',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _shopAddressCtrl,
              label: 'Adresse',
              hint: 'Rue 10, Dakar',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _savePrefs,
                child: const Text('Sauvegarder'),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── 3. Reçu ───────────────────────────────────────────────────────
          _section('Reçu', [
            _field(
              controller: _receiptHeaderCtrl,
              label: 'En-tête du reçu',
              hint: 'Boutique Aminata',
            ),
            const SizedBox(height: 12),
            _field(
              controller: _receiptFooterCtrl,
              label: 'Pied de page du reçu',
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
                onPressed: _savePrefs,
                child: const Text('Sauvegarder'),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── 4. Synchronisation ────────────────────────────────────────────
          _section('Synchronisation', [
            _infoRow(
              'Dernier sync',
              lastSync.when(
                data: (dt) => dt != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(dt)
                    : 'Jamais',
                loading: () => '…',
                error: (_, _) => '—',
              ),
            ),
            _infoRow(
              'Statut',
              _syncLabel(
                syncStatus.when(
                  data: (s) => s,
                  loading: () => SyncUiStatus.disconnected,
                  error: (_, _) => SyncUiStatus.error,
                ),
              ),
            ),
            _infoRow(
              'En attente',
              outboxCount.when(
                data: (n) => '$n élément${n > 1 ? 's' : ''}',
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
                    const SnackBar(
                        content: Text('Synchronisation déclenchée')),
                  );
                },
              ),
            ),
          ]),

          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // ── 5. Notifications ──────────────────────────────────────────────
          _section('Notifications', [
            SwitchListTile(
              key: const Key('notif_daily_summary_toggle'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Résumé quotidien activé'),
              value: _dailySummaryEnabled,
              onChanged: (val) => setState(() => _dailySummaryEnabled = val),
            ),
            if (_dailySummaryEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                key: const Key('notif_summary_time'),
                contentPadding: EdgeInsets.zero,
                title: const Text("Heure d'envoi"),
                trailing: Text(_dailySummaryTime, style: AppTextStyles.bodyMedium),
                onTap: _pickSummaryTime,
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: const Key('notif_channel_selector'),
              value: _notificationChannel,
              decoration: const InputDecoration(labelText: 'Canal'),
              items: const [
                DropdownMenuItem(value: 'in_app', child: Text('Application (in-app)')),
                DropdownMenuItem(
                  value: 'whatsapp',
                  enabled: false,
                  child: Text('WhatsApp (bientôt disponible)',
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _notificationChannel = val);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('notif_save_button'),
                onPressed: _savingNotif ? null : _saveNotificationSettings,
                child: _savingNotif
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sauvegarder'),
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── 6. Application ────────────────────────────────────────────────
          _section('Application', [
            _infoRow('Version', 'Scalario v1.0.0'),
            _infoRow('Serveur', ApiConstants.baseUrl),
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
          ]),

          const SizedBox(height: 32),
        ],
        ),
      ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────────────

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
            child: Text(header,
                style: AppTextStyles.titleMedium, textAlign: TextAlign.center),
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
              Text('TOTAL',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              Text('1 000 FCFA',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 12),
          Center(
            child: Text(
              footer,
              style:
                  AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatRole(String? role) {
    switch (role) {
      case 'owner':
        return 'Propriétaire';
      case 'manager':
        return 'Manager';
      case 'commercial':
        return 'Commercial';
      default:
        return role ?? '—';
    }
  }

  String _syncLabel(SyncUiStatus status) {
    switch (status) {
      case SyncUiStatus.connected:
        return 'Synchronisé';
      case SyncUiStatus.syncing:
        return 'En cours…';
      case SyncUiStatus.error:
        return 'Erreur';
      case SyncUiStatus.disconnected:
        return 'Déconnecté';
    }
  }
}
