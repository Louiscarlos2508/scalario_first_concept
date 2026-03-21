import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';

String _fcfa(double v) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(v);

class ClientOrderDocumentWidget extends ConsumerWidget {
  final ClientOrder order;

  const ClientOrderDocumentWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(_businessTypeConfigProvider);
    final documentType = configAsync.valueOrNull?.documentType ?? 'receipt';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Drag handle
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: switch (documentType) {
                'delivery_note' => _DeliveryNoteView(order: order),
                'invoice' => _InvoiceView(order: order),
                _ => _ReceiptView(order: order),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Fermer'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Receipt (default) ─────────────────────────────────────────────────────────

class _ReceiptView extends StatelessWidget {
  final ClientOrder order;
  const _ReceiptView({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Résumé de commande',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(order.orderNumber,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(DateFormat('dd/MM/yyyy').format(order.deliveredAt ?? order.createdAt)),
        const Divider(height: 16),
        ...order.lines.map((l) => _lineRow(
              l.catalogItemId.length > 8
                  ? l.catalogItemId.substring(0, 8)
                  : l.catalogItemId,
              l.deliveredQty,
              l.unitPrice,
            )),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_fcfa(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _lineRow(String name, double qty, double price) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(name)),
            Text('${qty.toStringAsFixed(0)} × ${_fcfa(price)}'),
            const SizedBox(width: 8),
            Text(_fcfa(qty * price)),
          ],
        ),
      );
}

// ── Delivery note ─────────────────────────────────────────────────────────────

class _DeliveryNoteView extends StatelessWidget {
  final ClientOrder order;
  const _DeliveryNoteView({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bon de livraison',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('N° ${order.orderNumber}'),
        Text('Date : ${DateFormat('dd/MM/yyyy').format(order.deliveredAt ?? order.createdAt)}'),
        const Divider(height: 16),
        const Text('Articles livrés :',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...order.lines.map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.catalogItemId.length > 8
                        ? l.catalogItemId.substring(0, 8)
                        : l.catalogItemId),
                  ),
                  Text('${l.deliveredQty.toStringAsFixed(0)} / ${l.quantity.toStringAsFixed(0)}'),
                ],
              ),
            )),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Signature livreur',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 32),
                  Divider(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Signature client',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 32),
                  Divider(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Invoice ───────────────────────────────────────────────────────────────────

class _InvoiceView extends StatelessWidget {
  final ClientOrder order;
  const _InvoiceView({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Facture simplifiée',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('N° ${order.orderNumber}'),
        Text('Date : ${DateFormat('dd/MM/yyyy').format(order.deliveredAt ?? order.createdAt)}'),
        const Divider(height: 16),
        ...order.lines.map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.catalogItemId.length > 8
                        ? l.catalogItemId.substring(0, 8)
                        : l.catalogItemId),
                  ),
                  Text(
                      '${l.deliveredQty.toStringAsFixed(0)} × ${_fcfa(l.unitPrice)}'),
                  const SizedBox(width: 8),
                  Text(_fcfa(l.deliveredQty * l.unitPrice)),
                ],
              ),
            )),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total HT',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_fcfa(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _businessTypeConfigProvider =
    FutureProvider<BusinessTypeConfig>((ref) async {
  // Use fallback — BusinessTypeConfigRepository loaded elsewhere
  return BusinessTypeConfig.fallback;
});
