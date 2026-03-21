import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_providers.dart';

class AdminBillingScreen extends ConsumerStatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  ConsumerState<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends ConsumerState<AdminBillingScreen> {
  String? _filterTenantId;
  String? _filterType;
  String? _filterStatus;

  (String?, String?, String?) get _filters =>
      (_filterTenantId, _filterType, _filterStatus);

  String _formatAmount(dynamic v) {
    final n = double.tryParse(v?.toString() ?? '0') ?? 0;
    if (n == 0) return '—';
    return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yy').format(dt);
  }

  Color _statusColor(String status) => switch (status) {
        'paid' => Colors.green,
        'overdue' => Colors.orange,
        'cancelled' => Colors.grey,
        'completed' => Colors.teal,
        _ => Colors.blue,
      };

  String _statusLabel(String status) => switch (status) {
        'paid' => 'Payé',
        'overdue' => 'En retard',
        'cancelled' => 'Annulé',
        'completed' => 'Terminé',
        _ => 'En attente',
      };

  String _typeLabel(String type) => switch (type) {
        'subscription' => 'Abonnement',
        'subscription_expired' => 'Abonnement expiré',
        'installation' => 'Installation',
        'training' => 'Formation',
        'plan_change' => 'Changement de plan',
        'activation' => 'Activation',
        'invoice' => 'Facture',
        _ => type,
      };

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(billingSummaryProvider);
    final eventsAsync = ref.watch(allBillingEventsProvider(_filters));
    final tenantsAsync = ref.watch(adminTenantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Facturation')),
      body: Column(
        children: [
          // ── KPI Bar ─────────────────────────────────────────────────────────
          summaryAsync.when(
            data: (s) => _KpiBar(summary: s),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
          ),

          // ── Filters ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Tenant filter
                Expanded(
                  child: tenantsAsync.when(
                    data: (tenants) => DropdownButtonFormField<String?>(
                      initialValue: _filterTenantId,
                      decoration: const InputDecoration(
                        labelText: 'Tenant',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous')),
                        ...tenants.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name,
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterTenantId = v),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                // Type filter
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterType,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(
                          value: 'subscription', child: Text('Abonnement')),
                      DropdownMenuItem(
                          value: 'installation', child: Text('Installation')),
                      DropdownMenuItem(
                          value: 'training', child: Text('Formation')),
                      DropdownMenuItem(
                          value: 'invoice', child: Text('Facture')),
                      DropdownMenuItem(
                          value: 'activation', child: Text('Activation')),
                    ],
                    onChanged: (v) => setState(() => _filterType = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Status filter
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'paid', child: Text('Payé')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('En attente')),
                      DropdownMenuItem(
                          value: 'overdue', child: Text('En retard')),
                    ],
                    onChanged: (v) => setState(() => _filterStatus = v),
                  ),
                ),
              ],
            ),
          ),

          // ── Events List ─────────────────────────────────────────────────────
          Expanded(
            child: eventsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                      child: Text('Aucun événement de facturation'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allBillingEventsProvider(_filters));
                    ref.invalidate(billingSummaryProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final event = events[i];
                      final tenantData =
                          event['tenant'] as Map<String, dynamic>?;
                      final tenantName =
                          tenantData?['name'] as String? ?? '—';
                      final status =
                          event['status'] as String? ?? 'pending';
                      final color = _statusColor(status);

                      return Card(
                        margin:
                            const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  color.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(4),
                              border: Border.all(color: color),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                  color: color, fontSize: 10),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  tenantName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatAmount(event['amount']),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${_typeLabel(event['type'] as String? ?? '')} • ${_formatDate(event['createdAt'] as String?)}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => _BillingEventDetailDialog(
                              event: event,
                              typeLabel: _typeLabel(event['type'] as String? ?? ''),
                              statusLabel: _statusLabel(status),
                              statusColor: color,
                              formatAmount: _formatAmount,
                              formatDate: _formatDate,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

// ── KPI Bar ────────────────────────────────────────────────────────────────────

class _KpiBar extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _KpiBar({required this.summary});

  String _fmt(num v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final revenue = (summary['monthlyRevenue'] as num?) ?? 0;
    final unpaid = (summary['totalUnpaid'] as num?) ?? 0;
    final pending = (summary['pendingInvoicesCount'] as num?) ?? 0;
    final overdue = (summary['overdueClients'] as num?) ?? 0;

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _KpiChip(
              label: 'Encaissé ce mois',
              value: '${_fmt(revenue)} FCFA',
              color: Colors.green),
          const SizedBox(width: 12),
          _KpiChip(
              label: 'Total impayé',
              value: '${_fmt(unpaid)} FCFA',
              color: unpaid > 0 ? Colors.orange : Colors.grey),
          const SizedBox(width: 12),
          _KpiChip(
              label: 'Factures en attente',
              value: '$pending',
              color: pending > 0 ? Colors.blue : Colors.grey),
          const SizedBox(width: 12),
          _KpiChip(
              label: 'Clients impayés',
              value: '$overdue',
              color: overdue > 0 ? Colors.red : Colors.grey,
              badge: overdue > 0),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool badge;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14)),
            if (badge) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6)),
                child: const Text('!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ── Billing Event Detail Dialog ────────────────────────────────────────────────

class _BillingEventDetailDialog extends StatelessWidget {
  final Map<String, dynamic> event;
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;
  final String Function(dynamic) formatAmount;
  final String Function(String?) formatDate;
  const _BillingEventDetailDialog({
    required this.event,
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.formatAmount,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final tenantData = event['tenant'] as Map<String, dynamic>?;
    final tenantName = tenantData?['name'] as String? ?? '—';
    final description = event['description'] as String?;
    final paymentMethod = event['paymentMethod'] as String?;
    final paymentRef = event['paymentRef'] as String?;
    final invoiceNumber = event['invoiceNumber'] as String?;
    final receiptNumber = event['receiptNumber'] as String?;
    final paidAt = event['paidAt'] as String?;

    final methodLabel = switch (paymentMethod) {
      'mobile_money' => 'Mobile Money',
      'bank_transfer' => 'Virement bancaire',
      'cash' => 'Espèces',
      null => null,
      _ => paymentMethod,
    };

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(typeLabel)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor),
            ),
            child: Text(statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11)),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row('Client', tenantName, bold: true),
            _Row('Montant', formatAmount(event['amount'])),
            _Row('Date', formatDate(event['createdAt'] as String?)),
            if (paidAt != null) _Row('Payé le', formatDate(paidAt)),
            if (description != null && description.isNotEmpty)
              _Row('Description', description),
            if (methodLabel != null) _Row('Méthode', methodLabel),
            if (paymentRef != null && paymentRef.isNotEmpty)
              _Row('Référence', paymentRef),
            if (invoiceNumber != null) _Row('N° Facture', invoiceNumber),
            if (receiptNumber != null) _Row('N° Reçu', receiptNumber),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}
