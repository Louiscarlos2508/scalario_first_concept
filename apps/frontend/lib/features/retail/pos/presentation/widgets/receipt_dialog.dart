import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/sheet_style.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/core/printing/printer_config_provider.dart';
import 'package:frontend/core/printing/receipt_data.dart';
import 'package:frontend/core/printing/receipt_printer_service.dart';

String _fcfa(double amount) =>
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0)
        .format(amount);

String _receiptTitle(String documentType) => switch (documentType) {
      'delivery_note' => 'Bon de livraison',
      'invoice' => 'Facture',
      _ => 'Reçu de vente',
    };

class ReceiptDialog extends ConsumerWidget {
  final Order order;
  final String tenantName;

  /// Original cart used to display promo strikethrough and total savings (AC5).
  final CartState? cartSnapshot;

  final String? customerName;

  const ReceiptDialog({
    super.key,
    required this.order,
    this.tenantName = 'Scalario POS',
    this.cartSnapshot,
    this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentType =
        ref.watch(businessTypeConfigProvider).valueOrNull?.documentType ??
            'receipt';
    final savings = _totalSavings();

    return Dialog(
      shape: kSheetDialogShape,
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Success header ─────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kSheetGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline,
                    color: kSheetGreen, size: 30),
              ),
              const SizedBox(height: 10),
              Text(
                _receiptTitle(documentType),
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: kSheetSlate900),
              ),
              Text(
                tenantName,
                style: const TextStyle(fontSize: 12, color: kSheetSlate500),
              ),
              const SizedBox(height: 16),
              const SheetDivider(),
              const SizedBox(height: 12),

              // ── Meta info ──────────────────────────────────────────────
              _InfoRow(
                  label: 'N° commande',
                  value: order.uuid.substring(0, 8).toUpperCase()),
              _InfoRow(
                  label: 'Date',
                  value: DateFormat('dd/MM/yyyy HH:mm')
                      .format(order.createdAt)),
              if (customerName != null)
                _InfoRow(label: 'Client', value: customerName!),
              const SizedBox(height: 10),
              const SheetDivider(),
              const SizedBox(height: 10),

              // ── Items ──────────────────────────────────────────────────
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Column(
                    children: _buildItemLines(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const SheetDivider(),
              const SizedBox(height: 10),

              // ── Total ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kSheetSlate500)),
                  Text(
                    _fcfa(order.totalAmount),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kSheetSlate900),
                  ),
                ],
              ),

              // ── Savings ────────────────────────────────────────────────
              if (savings > 0) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kSheetGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer_outlined,
                          size: 13, color: kSheetGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Économie : ${_fcfa(savings)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kSheetGreen),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Warranty ──────────────────────────────────────────────
              if (_warrantyItems().isNotEmpty) ...[
                const SizedBox(height: 12),
                const SheetDivider(),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Garanties',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSheetSlate500)),
                ),
                const SizedBox(height: 6),
                ..._warrantyItems(),
              ],

              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kSheetSlate50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments_outlined,
                        size: 14, color: kSheetSlate500),
                    const SizedBox(width: 6),
                    Text(
                      _paymentLabel(order.paymentMethod ?? ''),
                      style: const TextStyle(
                          fontSize: 12, color: kSheetSlate500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Actions ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: sheetCancelButtonStyle(),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: sheetPrimaryButtonStyle(),
                      onPressed: () async {
                        try {
                          final config = await ref
                              .read(printerConfigProvider.future);
                          final data = ReceiptData(
                            shopName: tenantName,
                            documentType: documentType,
                            date: order.createdAt,
                            orderRef:
                                order.uuid.substring(0, 8).toUpperCase(),
                            paymentMethod:
                                _paymentLabel(order.paymentMethod ?? ''),
                            customerName: customerName,
                            items: order.items
                                .map((i) => ReceiptLineItem(
                                      name: i.name ?? 'Article',
                                      quantity: i.quantity,
                                      unitPrice: i.price,
                                      total: i.total,
                                    ))
                                .toList(),
                            totalAmount: order.totalAmount,
                            subtotal: order.items.fold(
                                0.0, (s, i) => s + i.quantity * i.price),
                            discounts: order.items.fold(
                                0.0,
                                (s, i) =>
                                    s + (i.quantity * i.price - i.total)),
                          );
                          await ReceiptPrinterService.print(data, config);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Erreur d'impression : $e"),
                                  backgroundColor: kSheetRed),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('Imprimer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  String _paymentLabel(String method) => switch (method) {
        'CASH' => 'Espèces',
        'MOBILE_MONEY' => 'Mobile Money',
        'CARD' => 'Carte bancaire',
        'CREDIT' => 'À crédit',
        'SPLIT' => 'Paiement mixte',
        _ => method,
      };

  List<Widget> _buildItemLines() {
    if (cartSnapshot != null) {
      return cartSnapshot!.items.map((item) {
        final isWeighted = item.product.unitType != 'piece' &&
            item.product.pricePerUnit != null;
        final hasPromo = item.appliedPromoId != null && !item.isFreeItem;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.isFreeItem
                          ? '${item.product.name} (offert)'
                          : isWeighted
                              ? '${item.product.name} — ${item.quantity} ${item.product.weightUnit ?? ''}'
                              : '${item.product.name} ×${item.quantity.toInt()}',
                      style: const TextStyle(
                          fontSize: 12, color: kSheetSlate900),
                    ),
                  ),
                  if (hasPromo) ...[
                    Text(
                      _fcfa(item.originalSubtotal),
                      style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: kSheetSlate500,
                          fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Text(_fcfa(item.total),
                        style: const TextStyle(
                            color: kSheetGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ] else
                    Text(
                      item.isFreeItem ? '0 FCFA' : _fcfa(item.total),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kSheetSlate900),
                    ),
                ],
              ),
              if (hasPromo && item.appliedPromoLabel != null)
                Text(
                  '  ${item.appliedPromoLabel!}',
                  style: const TextStyle(
                      fontSize: 10,
                      color: kSheetGreen,
                      fontStyle: FontStyle.italic),
                ),
            ],
          ),
        );
      }).toList();
    }

    return order.items.map((item) {
      final isWeighted = item.unitType != null &&
          item.unitType != 'piece' &&
          item.pricePerUnit != null;
      final lineTotal = item.price * item.quantity;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                isWeighted
                    ? '${item.name} — ${item.quantity} ${item.unitLabel ?? ''} × ${_fcfa(item.pricePerUnit!)}'
                    : '${item.name} ×${item.quantity.toInt()}',
                style: const TextStyle(fontSize: 12, color: kSheetSlate900),
              ),
            ),
            Text(_fcfa(lineTotal),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kSheetSlate900)),
          ],
        ),
      );
    }).toList();
  }

  /// AC4 — Warranty rows for items with serialNumber + warrantyMonths.
  List<Widget> _warrantyItems() {
    if (cartSnapshot == null) return [];
    final dateFormat = DateFormat('dd/MM/yyyy');
    final soldAt = order.createdAt;
    final tenantCode =
        (order.tenantId ?? '????').substring(0, 4).toUpperCase();
    final rows = <Widget>[];

    for (final item in cartSnapshot!.items) {
      final serial = item.serialNumber;
      final months = item.product.warrantyMonths;
      if (serial == null || months == null || months <= 0) continue;
      final warrantyUntil =
          DateTime(soldAt.year, soldAt.month + months, soldAt.day);
      final yyyymm =
          '${soldAt.year}${soldAt.month.toString().padLeft(2, '0')}';
      final certNumber = 'WAR-$tenantCode-$serial-$yyyymm';

      rows.add(Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kSheetBlue.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kSheetBlue.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
            Text('N° série : $serial',
                style: const TextStyle(fontSize: 11, color: kSheetSlate500)),
            Text(
                'Valable jusqu\'au : ${dateFormat.format(warrantyUntil)}',
                style: const TextStyle(fontSize: 11, color: kSheetSlate500)),
            Text('Certificat : $certNumber',
                style: const TextStyle(
                    fontSize: 10, color: kSheetSlate500)),
          ],
        ),
      ));
    }
    return rows;
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: kSheetSlate500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kSheetSlate900)),
        ],
      ),
    );
  }
}
