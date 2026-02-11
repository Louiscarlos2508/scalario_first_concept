import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/features/pos/presentation/state/cart_state.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> generateAndPrintReceipt(CartState cart, String tenantName) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 5 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(tenantName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 2),
                    pw.Text('OFFICIAL RECEIPT', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),
              
              pw.Text('Date: ${formatter.format(now)}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Order Ref: ${cart.id ?? 'NEW-${now.millisecondsSinceEpoch}'}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Payment: ${cart.paymentMethod}', style: const pw.TextStyle(fontSize: 8)),
              
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 0.5),
              
              // Items Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('Item', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Total', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...cart.items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.product.name, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.quantity.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(currencyFormat.format(item.total), style: const pw.TextStyle(fontSize: 8)))),
                    ],
                  )),
                ],
              ),
              
              pw.Divider(thickness: 0.5),
              
              // Totals
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormat.format(cart.totalAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 10),
                    pw.BarcodeWidget(
                      data: cart.id ?? 'SALE-${now.millisecondsSinceEpoch}',
                      barcode: pw.Barcode.code128(),
                      width: 100,
                      height: 30,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'receipt_${now.millisecondsSinceEpoch}');
  }
}
