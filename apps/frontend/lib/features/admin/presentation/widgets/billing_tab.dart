import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../providers/admin_providers.dart';
import 'billing_event_tile.dart';

class BillingTab extends ConsumerWidget {
  final String tenantId;

  const BillingTab({super.key, required this.tenantId});

  String get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken ?? '';

  Color _billingStatusColor(String status) => switch (status) {
        'trial' => Colors.blue.shade300,
        'active' => Colors.green,
        'overdue' => Colors.orange,
        'suspended' => Colors.red,
        _ => Colors.grey,
      };

  Color _planColor(String plan) => switch (plan) {
        'standard' => Colors.blue,
        'premium' => Colors.purple,
        'enterprise' => const Color(0xFFB8860B),
        _ => Colors.grey,
      };

  Future<void> _togglePaid(
    WidgetRef ref,
    BuildContext context,
    String field,
    bool newValue,
  ) async {
    try {
      await ref.read(adminApiServiceProvider).updateTenantBilling(
            tenantId,
            {field: newValue},
            token: _token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveNotes(WidgetRef ref, BuildContext context, String notes) async {
    try {
      await ref.read(adminApiServiceProvider).updateTenantBilling(
            tenantId,
            {'notes': notes},
            token: _token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
    } catch (_) {}
  }

  Future<void> _reactivate(WidgetRef ref, BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réactiver le tenant'),
        content: const Text(
            'Confirmer la réactivation ? Le statut passera à "actif".'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Réactiver')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminApiServiceProvider).updateTenantBilling(
            tenantId,
            {'billingStatus': 'active'},
            token: _token,
          );
      ref.invalidate(tenantBillingProvider(tenantId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant réactivé')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingAsync = ref.watch(tenantBillingProvider(tenantId));

    return billingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (data) {
        final tenant = data['tenant'] as Map<String, dynamic>;
        final events = data['events'] as List? ?? [];
        final billingStatus = tenant['billingStatus'] as String? ?? 'trial';
        final plan = tenant['plan'] as String? ?? 'free';
        final statusColor = _billingStatusColor(billingStatus);
        final planColor = _planColor(plan);
        final notesCtrl = TextEditingController(
            text: tenant['notes'] as String? ?? '');

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Plan + billing status
            Row(
              children: [
                Chip(
                  label: Text(plan,
                      style: TextStyle(color: planColor, fontSize: 12)),
                  backgroundColor: planColor.withValues(alpha: 0.12),
                  side: BorderSide(color: planColor),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(billingStatus,
                      style: TextStyle(color: statusColor, fontSize: 12)),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  side: BorderSide(color: statusColor),
                ),
                if (billingStatus == 'suspended') ...[
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _reactivate(ref, context),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Réactiver'),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Dates
            if (tenant['trialEndsAt'] != null)
              _InfoRow(
                label: 'Fin essai',
                value: _formatDate(tenant['trialEndsAt'] as String),
              ),
            if (tenant['billingStartDate'] != null)
              _InfoRow(
                label: 'Début facturation',
                value: _formatDate(tenant['billingStartDate'] as String),
              ),
            const Divider(height: 24),

            // Installation fee
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Frais installation : ${_formatAmount(tenant['installationFee'])}',
                  ),
                ),
                Switch(
                  value: tenant['installationPaid'] as bool? ?? false,
                  onChanged: (v) =>
                      _togglePaid(ref, context, 'installationPaid', v),
                ),
                const Text('Payé'),
              ],
            ),

            // Training fee
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Frais formation : ${_formatAmount(tenant['trainingFee'])}',
                  ),
                ),
                Switch(
                  value: tenant['trainingPaid'] as bool? ?? false,
                  onChanged: (v) =>
                      _togglePaid(ref, context, 'trainingPaid', v),
                ),
                const Text('Payé'),
              ],
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onEditingComplete: () =>
                  _saveNotes(ref, context, notesCtrl.text),
              onTapOutside: (_) =>
                  _saveNotes(ref, context, notesCtrl.text),
            ),
            const Divider(height: 24),

            // Billing events
            Text('Historique', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (events.isEmpty)
              const Text('Aucun événement de facturation')
            else
              ...events.map((e) => BillingEventTile(
                    event: e as Map<String, dynamic>,
                    tenantId: tenantId,
                  )),
          ],
        );
      },
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '—';
    final n = double.tryParse(amount.toString()) ?? 0;
    if (n == 0) return '—';
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} FCFA';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(value),
        ],
      ),
    );
  }
}
