import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../providers/admin_providers.dart';

class BillingEventTile extends ConsumerWidget {
  final Map<String, dynamic> event;
  final String tenantId;

  const BillingEventTile({
    super.key,
    required this.event,
    required this.tenantId,
  });

  String get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken ?? '';

  Color _statusColor(String status) => switch (status) {
        'paid' => Colors.green,
        'overdue' => Colors.orange,
        'cancelled' => Colors.grey,
        _ => Colors.blue,
      };

  String _formatAmount(dynamic amount) {
    final n = double.tryParse(amount?.toString() ?? '0') ?? 0;
    return '${NumberFormat('#,###', 'fr_FR').format(n)} FCFA';
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
            'Marquer cet événement "${event['type']}" comme payé ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminApiServiceProvider).recordBillingEvent(
        tenantId,
        {
          'type': event['type'],
          'amount': event['amount']?.toString() ?? '0',
          'paidAt': DateTime.now().toIso8601String(),
          'description': event['description'],
        },
        token: _token,
      );
      ref.invalidate(tenantBillingProvider(tenantId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré')),
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
    final status = event['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final date = event['createdAt'] != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(event['createdAt'] as String))
        : '—';

    return ListTile(
      dense: true,
      leading: Chip(
        label: Text(status,
            style: TextStyle(color: color, fontSize: 11)),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color, width: 1),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      title: Text('${event['type']} — ${_formatAmount(event['amount'])}'),
      subtitle: Text(
          '${event['description'] ?? ''} • $date'),
      trailing: status == 'pending'
          ? TextButton(
              onPressed: () => _markPaid(context, ref),
              child: const Text('Marquer payé'),
            )
          : null,
    );
  }
}
