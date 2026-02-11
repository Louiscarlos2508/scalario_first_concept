import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text('SCALARIO - Z-REPORT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Divider(),
              pw.Text('Terminal: $tenantName'),
              pw.Text('Cashier: $userName'),
              pw.Text('Date: ${dateFormat.format(now)}'),
              pw.SizedBox(height: 10),
              
              pw.Text('SALES BY METHOD', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              ...totalsByMethod.entries.map((e) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(e.key),
                  pw.Text('\$${e.value.toStringAsFixed(2)}'),
                ],
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL SALES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${(summary['totalSales'] as double).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Text('CASH RECONCILIATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Opening Balance:'),
                   pw.Text('\$${(summary['openingBalance'] as double).toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Theoretical Cash:'),
                   pw.Text('\$${theoreticalCash.toStringAsFixed(2)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Physical Count:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                   pw.Text('\$${physicalCount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                   pw.Text('Variance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                   pw.Text('\$${variance.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Center(child: pw.Text('--- END OF REPORT ---')),
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
