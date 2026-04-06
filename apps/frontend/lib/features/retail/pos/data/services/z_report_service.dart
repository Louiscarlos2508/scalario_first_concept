import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:frontend/core/printing/printer_config.dart';
import 'package:frontend/core/printing/receipt_printer_service.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';

class ZReportService {
  ZReportService._();

  // ─── PDF ──────────────────────────────────────────────────────────────────

  static Future<void> savePdf({
    required Map<String, dynamic> summary,
    required double physicalCount,
    required String userName,
    required String tenantName,
  }) async {
    final now = DateTime.now();
    await Printing.layoutPdf(
      name: 'Z-Report-${DateFormat('yyyyMMdd-HHmm').format(now)}.pdf',
      onLayout: (_) => _buildPdfBytes(
        summary: summary,
        physicalCount: physicalCount,
        userName: userName,
        tenantName: tenantName,
      ),
    );
  }

  // ─── Thermal ──────────────────────────────────────────────────────────────

  static Future<void> printThermal({
    required Map<String, dynamic> summary,
    required double physicalCount,
    required String userName,
    required String tenantName,
    required PrinterConfig printerConfig,
  }) async {
    final bytes = await _buildEscPosBytes(
      summary: summary,
      physicalCount: physicalCount,
      userName: userName,
      tenantName: tenantName,
      paperWidth: printerConfig.paperWidth,
    );
    await ReceiptPrinterService.printRawBytes(bytes, printerConfig);
  }

  // ─── PDF builder ──────────────────────────────────────────────────────────

  static Future<Uint8List> _buildPdfBytes({
    required Map<String, dynamic> summary,
    required double physicalCount,
    required String userName,
    required String tenantName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(now);
    final currency =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    final theoreticalCash = summary['theoreticalCash'] as double;
    final variance = physicalCount - theoreticalCash;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final countsByMethod =
        (summary['countsByMethod'] as Map<String, int>?) ?? {};
    final totalSales = summary['totalSales'] as double;
    final orderCount = (summary['orderCount'] as int?) ?? 0;
    final splitCount = (summary['splitCount'] as int?) ?? 0;
    final openingBalance = (summary['openingBalance'] as double?) ?? 0.0;

    final darkSlate = PdfColor.fromHex('#0F172A');
    final slate500 = PdfColor.fromHex('#64748B');
    final slate200 = PdfColor.fromHex('#E2E8F0');
    final slate300 = PdfColor.fromHex('#94A3B8');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                decoration: pw.BoxDecoration(
                  color: darkSlate,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      tenantName.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'RAPPORT  Z',
                      style: pw.TextStyle(
                        color: slate300,
                        fontSize: 8,
                        letterSpacing: 2,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // ── Meta ────────────────────────────────────────────────────
              _pdfMeta('Date', dateStr, slate500),
              _pdfMeta('Caissier', userName, slate500),

              pw.SizedBox(height: 8),

              // ── Ventes ──────────────────────────────────────────────────
              _pdfSection(
                'ENCAISSEMENTS',
                '$orderCount vente${orderCount != 1 ? "s" : ""}',
                darkSlate,
                slate300,
              ),
              pw.Divider(color: slate200, thickness: 0.5),
              ...totalsByMethod.entries.map(
                (e) => _pdfPaymentRow(
                  paymentMethodLabel(e.key),
                  '${countsByMethod[e.key] ?? 0} tx',
                  currency.format(e.value),
                  slate500,
                ),
              ),
              if (splitCount > 0)
                pw.Text(
                  'dont $splitCount paiement${splitCount != 1 ? "s" : ""} '
                  'mixte${splitCount != 1 ? "s" : ""} ventilés',
                  style: pw.TextStyle(fontSize: 7, color: slate300),
                ),
              pw.Divider(color: slate200, thickness: 0.5),
              _pdfBoldRow('TOTAL VENTES', currency.format(totalSales), darkSlate),

              pw.SizedBox(height: 8),

              // ── Réconciliation ───────────────────────────────────────────
              _pdfSection('RÉCONCILIATION ESPÈCES', '', darkSlate, slate300),
              pw.Divider(color: slate200, thickness: 0.5),
              _pdfSimpleRow("Fond d'ouverture", currency.format(openingBalance), slate500),
              _pdfSimpleRow(
                '+ Espèces encaissées',
                currency.format(totalsByMethod['CASH'] ?? 0),
                slate500,
              ),
              _pdfSimpleRow('= Théorique caisse', currency.format(theoreticalCash), slate500),
              _pdfSimpleRow('Montant déclaré', currency.format(physicalCount), slate500),
              pw.Divider(color: slate200, thickness: 0.5),
              _pdfVarianceRow('Écart', variance, currency),

              pw.SizedBox(height: 16),

              // ── Footer ───────────────────────────────────────────────────
              pw.Divider(color: slate200, thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'Rapport généré le $dateStr',
                  style: pw.TextStyle(fontSize: 7, color: slate300),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfMeta(String label, String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          children: [
            pw.Text('$label : ',
                style: pw.TextStyle(fontSize: 8, color: color)),
            pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      );

  static pw.Widget _pdfSection(
    String title,
    String sub,
    PdfColor dark,
    PdfColor light,
  ) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2, bottom: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 8, color: dark),
            ),
            if (sub.isNotEmpty)
              pw.Text(sub,
                  style: pw.TextStyle(fontSize: 7, color: light)),
          ],
        ),
      );

  static pw.Widget _pdfPaymentRow(
    String label,
    String count,
    String amount,
    PdfColor color,
  ) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.Expanded(
                child: pw.Text(label, style: const pw.TextStyle(fontSize: 8))),
            pw.Text(count,
                style: pw.TextStyle(fontSize: 7, color: color)),
            pw.SizedBox(width: 8),
            pw.Text(amount,
                style: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );

  static pw.Widget _pdfSimpleRow(
    String label,
    String value,
    PdfColor labelColor,
  ) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 8, color: labelColor)),
            pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      );

  static pw.Widget _pdfBoldRow(String label, String value, PdfColor color) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9, color: color)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 9, color: color)),
          ],
        ),
      );

  static pw.Widget _pdfVarianceRow(
    String label,
    double variance,
    NumberFormat currency,
  ) {
    final color = variance == 0
        ? PdfColor.fromHex('#15803D')
        : variance > 0
            ? PdfColor.fromHex('#B45309')
            : PdfColor.fromHex('#C62828');
    final valueStr =
        '${variance > 0 ? "+" : ""}${currency.format(variance)}';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9, color: color)),
          pw.Text(valueStr,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9, color: color)),
        ],
      ),
    );
  }

  // ─── ESC/POS builder ──────────────────────────────────────────────────────

  static Future<List<int>> _buildEscPosBytes({
    required Map<String, dynamic> summary,
    required double physicalCount,
    required String userName,
    required String tenantName,
    required PaperWidth paperWidth,
  }) async {
    final profile = await CapabilityProfile.load();
    final size =
        paperWidth == PaperWidth.mm58 ? PaperSize.mm58 : PaperSize.mm80;
    final gen = Generator(size, profile);
    final currency =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final theoreticalCash = summary['theoreticalCash'] as double;
    final variance = physicalCount - theoreticalCash;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final countsByMethod =
        (summary['countsByMethod'] as Map<String, int>?) ?? {};
    final totalSales = summary['totalSales'] as double;
    final orderCount = (summary['orderCount'] as int?) ?? 0;
    final splitCount = (summary['splitCount'] as int?) ?? 0;
    final openingBalance = (summary['openingBalance'] as double?) ?? 0.0;

    List<int> bytes = [];

    // ── Header ───────────────────────────────────────────────────────────────
    bytes.addAll(gen.setStyles(const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2)));
    bytes.addAll(gen.text(tenantName));
    bytes.addAll(gen.setStyles(
        const PosStyles(align: PosAlign.center)));
    bytes.addAll(gen.text('RAPPORT Z'));
    bytes.addAll(gen.hr());

    // ── Meta ─────────────────────────────────────────────────────────────────
    bytes.addAll(gen.setStyles(const PosStyles()));
    bytes.addAll(gen.text('Date     : $dateStr'));
    bytes.addAll(gen.text('Caissier : $userName'));
    bytes.addAll(gen.hr());

    // ── Ventes ───────────────────────────────────────────────────────────────
    bytes.addAll(gen.setStyles(const PosStyles(bold: true)));
    bytes.addAll(
        gen.text('ENCAISSEMENTS ($orderCount vente${orderCount != 1 ? "s" : ""})'));
    bytes.addAll(gen.setStyles(const PosStyles()));
    bytes.addAll(gen.hr(ch: '-'));

    for (final entry in totalsByMethod.entries) {
      final label = paymentMethodLabel(entry.key);
      final count = '${countsByMethod[entry.key] ?? 0} tx';
      final amount = currency.format(entry.value);
      bytes.addAll(gen.row([
        PosColumn(text: label, width: 6),
        PosColumn(
            text: count,
            width: 2,
            styles: const PosStyles(align: PosAlign.center)),
        PosColumn(
            text: amount,
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
    }

    if (splitCount > 0) {
      bytes.addAll(gen.setStyles(
          const PosStyles(fontType: PosFontType.fontB)));
      bytes.addAll(gen.text(
          'dont $splitCount paiement${splitCount != 1 ? "s" : ""} '
          'mixte${splitCount != 1 ? "s" : ""} ventilés'));
      bytes.addAll(gen.setStyles(const PosStyles()));
    }

    bytes.addAll(gen.hr());
    bytes.addAll(gen.row([
      PosColumn(
          text: 'TOTAL VENTES',
          width: 7,
          styles: const PosStyles(bold: true)),
      PosColumn(
          text: currency.format(totalSales),
          width: 5,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]));

    bytes.addAll(gen.feed(1));

    // ── Réconciliation ────────────────────────────────────────────────────────
    bytes.addAll(gen.setStyles(const PosStyles(bold: true)));
    bytes.addAll(gen.text('RÉCONCILIATION ESPÈCES'));
    bytes.addAll(gen.setStyles(const PosStyles()));
    bytes.addAll(gen.hr(ch: '-'));

    bytes.addAll(gen.row([
      PosColumn(text: "Fond d'ouverture", width: 7),
      PosColumn(
          text: currency.format(openingBalance),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: '+ Espèces', width: 7),
      PosColumn(
          text: currency.format(totalsByMethod['CASH'] ?? 0),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(text: '= Théorique', width: 7),
      PosColumn(
          text: currency.format(theoreticalCash),
          width: 5,
          styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(gen.row([
      PosColumn(
          text: 'Déclaré',
          width: 7,
          styles: const PosStyles(bold: true)),
      PosColumn(
          text: currency.format(physicalCount),
          width: 5,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]));

    bytes.addAll(gen.hr());
    bytes.addAll(gen.row([
      PosColumn(
          text: 'Écart',
          width: 7,
          styles: const PosStyles(bold: true)),
      PosColumn(
          text:
              '${variance > 0 ? "+" : ""}${currency.format(variance)}',
          width: 5,
          styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]));

    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.setStyles(const PosStyles(
        align: PosAlign.center, fontType: PosFontType.fontB)));
    bytes.addAll(gen.text('--- FIN DU RAPPORT ---'));
    bytes.addAll(gen.feed(2));
    bytes.addAll(gen.cut());

    return bytes;
  }
}
