import 'package:flutter/material.dart';

class BillingHistoryList extends StatelessWidget {
  final List<dynamic> events;

  const BillingHistoryList({super.key, required this.events});

  Color _statusColor(String status) => switch (status) {
        'paid' => Colors.green,
        'overdue' => Colors.orange,
        'cancelled' => Colors.grey,
        _ => Colors.blue,
      };

  String _statusLabel(String status) => switch (status) {
        'paid' => 'Payé',
        'overdue' => 'En attente de paiement',
        'cancelled' => 'Annulé',
        _ => 'En attente',
      };

  String _typeLabel(String type) => switch (type) {
        'subscription' => 'Abonnement',
        'installation' => 'Installation',
        'training' => 'Formation',
        'upgrade' => 'Mise à niveau',
        'downgrade' => 'Rétrogradation',
        'payment' => 'Paiement',
        'upgrade_request' => 'Demande d\'upgrade',
        _ => type,
      };

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatAmount(dynamic amount) {
    final n = double.tryParse(amount?.toString() ?? '0') ?? 0;
    if (n == 0) return '—';
    return '${n.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Aucun historique de paiement')),
      );
    }

    return Column(
      children: events.map((e) {
        final event = e as Map<String, dynamic>;
        final status = event['status'] as String? ?? 'pending';
        final color = _statusColor(status);

        return ListTile(
          dense: true,
          leading: Icon(Icons.receipt_outlined, color: color, size: 20),
          title: Text(
              '${_typeLabel(event['type'] as String? ?? '')} — ${_formatAmount(event['amount'])}'),
          subtitle: Text(
            '${_statusLabel(status)} • ${_formatDate(event['createdAt'] as String?)}',
            style: TextStyle(color: color, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}
