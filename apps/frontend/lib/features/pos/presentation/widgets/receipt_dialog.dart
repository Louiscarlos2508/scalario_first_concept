import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/pos/data/models/order.dart';

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
      title: const Center(child: Text('Receipt')),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tenantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(),
              _buildInfoRow('Order ID:', order.uuid.substring(0, 8)),
              _buildInfoRow('Date:', DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt ?? DateTime.now())),
              const Divider(),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('${item.name} x${item.quantity.toInt()}')),
                    Text('\$ ${(item.price * item.quantity).toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$ ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Payment: ${order.paymentMethod}', style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              const Text('Thank you for your business!', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // TODO: Implement PDF generation/printing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printing PDF... (Demo)')),
            );
          },
          icon: const Icon(Icons.print),
          label: const Text('Print Receipt'),
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
