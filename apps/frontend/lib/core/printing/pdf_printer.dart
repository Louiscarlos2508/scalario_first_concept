import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'receipt_data.dart';

/// Prints [ReceiptData] via the system print dialog (PDF).
Future<void> printPdf(ReceiptData data) async {
  final pdf = pw.Document();
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  pdf.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm, double.infinity,
          marginAll: 5 * PdfPageFormat.mm),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(data.shopName,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text(_docTitle(data.documentType),
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),

            // ── Meta ─────────────────────────────────────────────────────
            pw.Text('Date : ${dateFormat.format(data.date)}',
                style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Ref  : ${data.orderRef}',
                style: const pw.TextStyle(fontSize: 8)),
            if (data.customerName != null)
              pw.Text('Client : ${data.customerName}',
                  style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Paiement : ${data.paymentMethod}',
                style: const pw.TextStyle(fontSize: 8)),

            pw.SizedBox(height: 5),
            pw.Divider(thickness: 0.5),

            // ── Items ─────────────────────────────────────────────────────
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(children: [
                  pw.Text('Article',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Qté',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('Total',
                        style: pw.TextStyle(
                            fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                ]),
                ...data.items.map((item) {
                  final qtyStr = item.quantity % 1 == 0
                      ? item.quantity.toInt().toString()
                      : item.quantity.toStringAsFixed(2);
                  return pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text(item.name,
                            style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text(qtyStr,
                            style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 2),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(currency.format(item.total),
                            style: const pw.TextStyle(fontSize: 8)),
                      ),
                    ),
                  ]);
                }),
              ],
            ),

            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 5),

            // ── Totals ────────────────────────────────────────────────────
            if (data.discounts > 0)
              _billRow('Remises', data.discounts, currency,
                  isNegative: true),

            _billRow('TOTAL', data.totalAmount, currency, isBold: true),

            pw.SizedBox(height: 20),

            // ── Footer ────────────────────────────────────────────────────
            pw.Center(
              child: pw.Text('Merci pour votre achat !',
                  style: pw.TextStyle(
                      fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'recu_${data.date.millisecondsSinceEpoch}');
}

pw.Widget _billRow(String label, double amount, NumberFormat fmt,
    {bool isBold = false, bool isNegative = false}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(label,
          style: pw.TextStyle(
              fontSize: isBold ? 10 : 8,
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      pw.Text(
        '${isNegative ? "-" : ""}${fmt.format(amount)}',
        style: pw.TextStyle(
            fontSize: isBold ? 10 : 8,
            fontWeight:
                isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    ],
  );
}

String _docTitle(String type) => switch (type) {
      'delivery_note' => 'BON DE LIVRAISON',
      'invoice' => 'FACTURE',
      _ => 'TICKET DE CAISSE',
    };
