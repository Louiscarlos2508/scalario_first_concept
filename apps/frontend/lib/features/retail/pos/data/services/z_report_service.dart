import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';

class ZReportService {
  static Future<void> generateAndPrintZReport({
    required Map<String, dynamic> summary,
    required double physicalCount,
    required String userName,
    required String tenantName,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    final theoreticalCash = summary['theoreticalCash'] as double;
    final variance = physicalCount - theoreticalCash;
    final totalsByMethod = summary['totalsByMethod'] as Map<String, double>;
    final totalSales = summary['totalSales'] as double;
    final orderCount = (summary['orderCount'] as int?) ?? 0;
    final splitCount = (summary['splitCount'] as int?) ?? 0;
    final openingBalance = (summary['openingBalance'] as double?) ?? 0.0;

    pw.Widget row(String label, String value, {bool bold = false}) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
            pw.Text(value,
                style: pw.TextStyle(
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                  child: pw.Text('SCALARIO - Z-REPORT',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Divider(),
              pw.Text('Terminal : $tenantName'),
              pw.Text('Caissier : $userName'),
              pw.Text('Date : ${dateFormat.format(now)}'),
              pw.SizedBox(height: 10),

              pw.Text('ENCAISSEMENTS PAR MÉTHODE',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('$orderCount vente${orderCount > 1 ? 's' : ''}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              ...totalsByMethod.entries.map(
                (e) => row(paymentMethodLabel(e.key),
                    '${e.value.toStringAsFixed(0)} FCFA'),
              ),
              if (splitCount > 0)
                pw.Text(
                  'dont $splitCount paiement${splitCount > 1 ? 's' : ''} mixte${splitCount > 1 ? 's' : ''} ventilés',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.Divider(),
              row('TOTAL VENTES',
                  '${totalSales.toStringAsFixed(0)} FCFA', bold: true),

              pw.SizedBox(height: 20),
              pw.Text('RÉCONCILIATION ESPÈCES',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              row('Fond de caisse', '${openingBalance.toStringAsFixed(0)} FCFA'),
              row('+ Espèces reçues',
                  '${(totalsByMethod['CASH'] ?? 0).toStringAsFixed(0)} FCFA'),
              row('= Théorique caisse',
                  '${theoreticalCash.toStringAsFixed(0)} FCFA'),
              row('Montant déclaré',
                  '${physicalCount.toStringAsFixed(0)} FCFA', bold: true),
              pw.Divider(),
              row('Écart', '${variance.toStringAsFixed(0)} FCFA', bold: true),

              pw.SizedBox(height: 30),
              pw.Center(child: pw.Text('--- FIN DU RAPPORT ---')),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Z-Report-${now.millisecondsSinceEpoch}.pdf',
    );
  }
}
