import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/core/services/receipt_service.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

class ReceiptDialog extends StatelessWidget {
  final Order order;
  final String tenantName;
  /// Original cart used to display promo strikethrough and total savings (AC5).
  final CartState? cartSnapshot;

  const ReceiptDialog({
    super.key,
    required this.order,
    this.tenantName = 'Scalario POS',
    this.cartSnapshot,
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
                      .format(order.createdAt)),
              const Divider(),
              ..._buildItemLines(),
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
              // AC5 (Story 25-7) — Total savings footer
              if (_totalSavings() > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Vous avez économisé :',
                          style: TextStyle(
                              color: Colors.green, fontStyle: FontStyle.italic)),
                      Text(
                        _fcfa(_totalSavings()),
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              // Epic 26 — Warranty section (AC4)
              if (_warrantyItems().isNotEmpty) ...[
                const Divider(),
                const Text('Garanties', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._warrantyItems(),
              ],
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

  double _totalSavings() {
    if (cartSnapshot == null) return 0;
    return cartSnapshot!.items.fold(0.0, (sum, item) {
      if (item.appliedPromoId != null && !item.isFreeItem) {
        return sum + (item.originalSubtotal - item.total);
      }
      return sum;
    });
  }

  List<Widget> _buildItemLines() {
    // When cart snapshot available, use it for promo strikethrough display
    if (cartSnapshot != null) {
      return cartSnapshot!.items.map((item) {
        final isWeighted = item.product.unitType != 'piece' &&
            item.product.pricePerUnit != null;
        final hasPromo = item.appliedPromoId != null && !item.isFreeItem;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(item.isFreeItem
                        ? '${item.product.name} (offert)'
                        : isWeighted
                            ? '${item.product.name} — ${item.quantity} ${item.product.weightUnit ?? ''}'
                            : '${item.product.name} ×${item.quantity.toInt()}'),
                  ),
                  if (hasPromo) ...[
                    Text(
                      _fcfa(item.originalSubtotal),
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(_fcfa(item.total),
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ] else
                    Text(item.isFreeItem ? '0 FCFA' : _fcfa(item.total)),
                ],
              ),
              if (hasPromo && item.appliedPromoLabel != null)
                Text('  ${item.appliedPromoLabel!}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontStyle: FontStyle.italic)),
            ],
          ),
        );
      }).toList();
    }

    // Fallback: order items without promo info
    return order.items.map((item) {
      final isWeighted = item.unitType != null &&
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
    }).toList();
  }

  /// AC4 — Builds warranty rows for items with serialNumber + warrantyMonths.
  List<Widget> _warrantyItems() {
    if (cartSnapshot == null) return [];
    final dateFormat = DateFormat('dd/MM/yyyy');
    final soldAt = order.createdAt;
    final tenantCode = (order.tenantId ?? '????').substring(0, 4).toUpperCase();
    final rows = <Widget>[];

    for (final item in cartSnapshot!.items) {
      final serial = item.serialNumber;
      final months = item.product.warrantyMonths;
      if (serial == null || months == null || months <= 0) continue;
      final warrantyUntil = DateTime(soldAt.year, soldAt.month + months, soldAt.day);
      final yyyymm = '${soldAt.year}${soldAt.month.toString().padLeft(2, '0')}';
      final certNumber = 'WAR-$tenantCode-$serial-$yyyymm';
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            Text('N° série : $serial', style: const TextStyle(fontSize: 11)),
            Text('Valable jusqu\'au : ${dateFormat.format(warrantyUntil)}', style: const TextStyle(fontSize: 11)),
            Text('Certificat : $certNumber', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ));
    }
    return rows;
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
