import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'printer_config.dart';
import 'receipt_data.dart';

/// Builds ESC/POS byte list from [ReceiptData].
Future<List<int>> buildEscPosReceipt(
    ReceiptData data, PaperWidth paperWidth) async {
  final profile = await CapabilityProfile.load();
  final size =
      paperWidth == PaperWidth.mm58 ? PaperSize.mm58 : PaperSize.mm80;
  final gen = Generator(size, profile);
  final currency = NumberFormat.currency(
      locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  List<int> bytes = [];

  // ── Header ──────────────────────────────────────────────────────────────
  bytes.addAll(gen.setStyles(const PosStyles(
      align: PosAlign.center, bold: true, height: PosTextSize.size2)));
  bytes.addAll(gen.text(data.shopName));
  bytes.addAll(gen.setStyles(const PosStyles(align: PosAlign.center)));
  bytes.addAll(gen.text(_docTitle(data.documentType)));
  bytes.addAll(gen.feed(1));

  // ── Meta ────────────────────────────────────────────────────────────────
  bytes.addAll(gen.setStyles(const PosStyles()));
  bytes.addAll(gen.text(
      'Date : ${DateFormat('dd/MM/yyyy HH:mm').format(data.date)}'));
  bytes.addAll(gen.text('Ref  : ${data.orderRef}'));
  if (data.customerName != null) {
    bytes.addAll(gen.text('Client : ${data.customerName}'));
  }
  bytes.addAll(gen.text('Paiem : ${data.paymentMethod}'));
  bytes.addAll(gen.hr());

  // ── Items ────────────────────────────────────────────────────────────────
  bytes.addAll(gen.row([
    PosColumn(
        text: 'Article',
        width: 7,
        styles: const PosStyles(bold: true)),
    PosColumn(
        text: 'Qté',
        width: 1,
        styles: const PosStyles(bold: true, align: PosAlign.center)),
    PosColumn(
        text: 'Total',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right)),
  ]));
  bytes.addAll(gen.hr(ch: '-'));

  for (final item in data.items) {
    final qtyStr = item.quantity % 1 == 0
        ? item.quantity.toInt().toString()
        : item.quantity.toStringAsFixed(2);
    bytes.addAll(gen.row([
      PosColumn(text: item.name, width: 7),
      PosColumn(
          text: qtyStr,
          width: 1,
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: currency.format(item.total),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
  }

  bytes.addAll(gen.hr());

  // ── Totals ───────────────────────────────────────────────────────────────
  if (data.discounts > 0) {
    bytes.addAll(gen.row([
      PosColumn(text: 'Remises', width: 8),
      PosColumn(
          text: '-${currency.format(data.discounts)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
  }
  bytes.addAll(gen.row([
    PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(bold: true, height: PosTextSize.size2)),
    PosColumn(
        text: currency.format(data.totalAmount),
        width: 4,
        styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            align: PosAlign.right)),
  ]));

  // ── Footer ───────────────────────────────────────────────────────────────
  bytes.addAll(gen.feed(1));
  bytes.addAll(gen.setStyles(
      const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB)));
  bytes.addAll(gen.text('Merci pour votre achat !'));
  bytes.addAll(gen.feed(2));
  bytes.addAll(gen.cut());

  return bytes;
}

String _docTitle(String type) => switch (type) {
      'delivery_note' => 'BON DE LIVRAISON',
      'invoice' => 'FACTURE',
      _ => 'TICKET DE CAISSE',
    };
