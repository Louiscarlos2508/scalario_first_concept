import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

({Color bg, Color fg, String label}) _statusInfo(String status) {
  return switch (status) {
    'draft' => (bg: Colors.grey.shade200, fg: Colors.grey.shade700, label: 'Brouillon'),
    'confirmed' => (bg: Colors.blue.shade100, fg: Colors.blue.shade800, label: 'Confirmée'),
    'in-progress' => (bg: Colors.orange.shade100, fg: Colors.orange.shade800, label: 'En préparation'),
    'ready' => (bg: Colors.orange.shade200, fg: Colors.orange.shade900, label: 'Prête'),
    'delivered' => (bg: Colors.green.shade100, fg: Colors.green.shade800, label: 'Livrée'),
    'invoiced' => (bg: Colors.green.shade200, fg: Colors.green.shade900, label: 'Facturée'),
    'paid' => (bg: Colors.green.shade300, fg: Colors.green.shade900, label: 'Payée'),
    'cancelled' => (bg: Colors.red.shade100, fg: Colors.red.shade800, label: 'Annulée'),
    _ => (bg: Colors.grey.shade200, fg: Colors.grey.shade700, label: status),
  };
}

class ClientOrderCard extends StatelessWidget {
  final ClientOrder order;
  final String? userRole;
  final VoidCallback? onTap;
  final Future<void> Function()? onConfirm;
  final Future<void> Function()? onPrepare;
  final Future<void> Function()? onDeliver;
  final Future<void> Function()? onCancel;

  const ClientOrderCard({
    super.key,
    required this.order,
    this.userRole,
    this.onTap,
    this.onConfirm,
    this.onPrepare,
    this.onDeliver,
    this.onCancel,
  });

  bool get _isOwnerOrManager =>
      userRole == 'owner' || userRole == 'manager';

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(order.status);
    final dateStr = DateFormat('dd/MM/yyyy').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: info.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      info.label,
                      style: TextStyle(
                          color: info.fg,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (order.customerName != null)
                Text(
                  order.customerName!,
                  style: const TextStyle(color: Colors.grey),
                )
              else
                Text(
                  order.customerId.length > 8
                      ? order.customerId.substring(0, 8)
                      : order.customerId,
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 4),
              Text(
                _fcfa(order.totalAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (order.status == 'draft' && _isOwnerOrManager && onConfirm != null) {
      actions.add(_actionButton(
        context,
        label: 'Valider',
        color: Colors.blue,
        onPressed: onConfirm!,
      ));
    }

    if (order.status == 'confirmed' && onPrepare != null) {
      actions.add(_actionButton(
        context,
        label: 'Préparer',
        color: Colors.orange,
        onPressed: onPrepare!,
      ));
    }

    if ((order.status == 'in-progress' || order.status == 'ready') &&
        onDeliver != null) {
      actions.add(_actionButton(
        context,
        label: 'Livrer',
        color: Colors.green,
        onPressed: onDeliver!,
      ));
    }

    if ((order.status == 'draft' || order.status == 'confirmed') &&
        _isOwnerOrManager &&
        onCancel != null) {
      actions.add(_actionButton(
        context,
        label: 'Annuler',
        color: Colors.red,
        onPressed: onCancel!,
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(spacing: 8, runSpacing: 4, children: actions),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String label,
    required Color color,
    required Future<void> Function() onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () async {
        try {
          await onPressed();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Erreur : $e'),
                  backgroundColor: Colors.red),
            );
          }
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
