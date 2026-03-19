import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/core/services/receipt_service.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ReceiptDialog extends StatelessWidget {
  final Order order;
  final String tenantName;

  const ReceiptDialog({
    super.key,
    required this.order,
    this.tenantName = 'Scalario POS',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Reçu')),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tenantName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              _buildInfoRow(
                  'N° commande :', order.uuid.substring(0, 8)),
              _buildInfoRow(
                  'Date :',
                  DateFormat('yyyy-MM-dd HH:mm')
                      .format(order.createdAt ?? DateTime.now())),
              const Divider(),
              ...order.items.map((item) {
                    final isWeighted =
                        item.unitType != null &&
                        item.unitType != 'piece' &&
                        item.pricePerUnit != null;
                    final lineTotal = item.price * item.quantity;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(isWeighted
                                ? '${item.name} — ${item.quantity} ${item.unitLabel ?? ''} × ${_fcfa(item.pricePerUnit!)}'
                                : '${item.name} x${item.quantity.toInt()}'),
                          ),
                          Text(_fcfa(lineTotal)),
                        ],
                      ),
                    );
                  }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL :',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    _fcfa(order.totalAmount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Paiement : ${order.paymentMethod}',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              const Text('Merci pour votre achat !',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            try {
              await ReceiptService.printOrder(order, tenantName);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Erreur d\'impression : $e')),
                );
              }
            }
          },
          icon: const Icon(Icons.print),
          label: const Text('Imprimer'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }
}
