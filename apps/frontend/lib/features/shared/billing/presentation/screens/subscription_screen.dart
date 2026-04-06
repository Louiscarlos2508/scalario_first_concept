import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/widgets/scalario_app_bar.dart';
import '../providers/subscription_provider.dart';
import '../widgets/plan_info_card.dart';
import '../widgets/billing_history_list.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _upgradeRequested = false;

  static const _kUpgradeRequestedKey = 'billing_upgrade_requested_at';

  @override
  void initState() {
    super.initState();
    _checkUpgradeState();
  }

  Future<void> _checkUpgradeState() async {
    final prefs = await SharedPreferences.getInstance();
    final requestedAt = prefs.getInt(_kUpgradeRequestedKey);
    if (requestedAt != null) {
      final elapsed =
          DateTime.now().millisecondsSinceEpoch - requestedAt;
      if (elapsed < 24 * 60 * 60 * 1000) {
        if (mounted) setState(() => _upgradeRequested = true);
      } else {
        await prefs.remove(_kUpgradeRequestedKey);
      }
    }
  }

  String get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken ?? '';

  String get _tenantId => ref.read(activeTenantProvider) ?? '';

  Color _billingStatusColor(String status) => switch (status) {
        'trial' => Colors.blue.shade300,
        'active' => Colors.green,
        'overdue' => Colors.orange,
        'suspended' => Colors.red,
        _ => Colors.grey,
      };

  String _billingStatusLabel(String status) => switch (status) {
        'trial' => 'Période d\'essai',
        'active' => 'Actif',
        'overdue' => 'En retard',
        'suspended' => 'Suspendu',
        _ => status,
      };

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String? _nextDueDate(String? billingStartDate) {
    if (billingStartDate == null) return null;
    final dt = DateTime.tryParse(billingStartDate);
    if (dt == null) return null;
    final next = dt.add(const Duration(days: 30));
    return '${next.day.toString().padLeft(2, '0')}/${next.month.toString().padLeft(2, '0')}/${next.year}';
  }

  Future<void> _requestUpgrade() async {
    String? message;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Demander un upgrade'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Message pour l\'administrateur (optionnel)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (v) => message = v.isEmpty ? null : v,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Envoyer')),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await ref.read(subscriptionRepositoryProvider).requestUpgrade(
            token: _token,
            tenantId: _tenantId,
            message: message,
          );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _kUpgradeRequestedKey, DateTime.now().millisecondsSinceEpoch);
      if (mounted) {
        setState(() => _upgradeRequested = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Votre demande a été envoyée. Carlos vous contactera sous 24h.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: const ScalarioAppBar(title: 'Mon abonnement'),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (data) {
          final plan = data['plan'] as Map<String, dynamic>? ?? {};
          final billingStatus = data['billingStatus'] as String? ?? 'trial';
          final trialEndsAt = data['trialEndsAt'] as String?;
          final billingStartDate = data['billingStartDate'] as String?;
          final events = data['events'] as List? ?? [];
          final statusColor = _billingStatusColor(billingStatus);
          final nextDue = _nextDueDate(billingStartDate);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PlanInfoCard(plan: plan),
              const SizedBox(height: 16),

              // Billing status section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Statut :',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_billingStatusLabel(billingStatus),
                                style: TextStyle(
                                    color: statusColor, fontSize: 12)),
                            backgroundColor:
                                statusColor.withValues(alpha: 0.12),
                            side: BorderSide(color: statusColor),
                          ),
                        ],
                      ),
                      if (trialEndsAt != null) ...[
                        const SizedBox(height: 8),
                        Text('Fin de l\'essai : ${_formatDate(trialEndsAt)}'),
                      ],
                      if (nextDue != null) ...[
                        const SizedBox(height: 8),
                        Text('Prochaine échéance : $nextDue'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Upgrade request button
              FilledButton.icon(
                onPressed: _upgradeRequested ? null : _requestUpgrade,
                icon: const Icon(Icons.upgrade),
                label: Text(_upgradeRequested
                    ? 'Demande envoyée'
                    : 'Demander un upgrade'),
              ),
              const SizedBox(height: 24),

              // History
              Text('Historique',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              BillingHistoryList(events: events),
            ],
          );
        },
      ),
    );
  }
}
