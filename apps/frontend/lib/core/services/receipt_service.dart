import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:intl/intl.dart';

class ReceiptService {
  static Future<void> generateAndPrintReceipt(CartState cart, String tenantName) async {
    final now = DateTime.now();
    await _generatePdf(
      tenantName: tenantName,
      date: now,
      orderRef: cart.id?.toString() ?? 'NEW-${now.millisecondsSinceEpoch}',
      paymentMethod: cart.paymentMethod,
      items: cart.items.map((i) => ReceiptItem(
        name: i.product.name,
        quantity: i.quantity.toDouble(),
        price: i.product.price,
        total: i.total,
        discountAmount: i.discountAmount,
        discountType: i.discountType,
      )).toList(),
      totalAmount: cart.totalAmount,
      subtotal: cart.items.fold(0.0, (sum, item) => sum + item.subtotal),
      discounts: cart.items.fold(0.0, (sum, item) => sum + (item.subtotal - item.total)),
    );
  }

  static Future<void> printOrder(Order order, String tenantName) async {
    await _generatePdf(
      tenantName: tenantName,
      date: order.createdAt,
      orderRef: order.uuid.substring(0, 8),
      paymentMethod: order.paymentMethod ?? 'CASH',
      items: order.items.map((i) => ReceiptItem(
        name: i.name ?? 'Unknown Item',
        quantity: i.quantity,
        price: i.price,
        total: i.total, // Ensure PosCartItem has a total getter or calculate it
        discountAmount: i.discountAmount,
        discountType: i.discountType,
      )).toList(),
      totalAmount: order.totalAmount,
      subtotal: order.items.fold(0.0, (sum, item) => sum + (item.quantity * item.price)), // Recalculate subtotal
      discounts: order.items.fold(0.0, (sum, item) => sum + ((item.quantity * item.price) - item.total)), // Recalculate discount
    );
  }

  static Future<void> _generatePdf({
    required String tenantName,
    required DateTime date,
    required String orderRef,
    required String paymentMethod,
    required List<ReceiptItem> items,
    required double totalAmount,
    required double subtotal,
    required double discounts,
  }) async {
    final pdf = pw.Document();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

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
              
              pw.Text('Date: ${formatter.format(date)}', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Order Ref: $orderRef', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Payment: $paymentMethod', style: const pw.TextStyle(fontSize: 8)),
              
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
                  ...items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.name, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(item.quantity.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text(currencyFormat.format(item.total), style: const pw.TextStyle(fontSize: 8)))),
                    ],
                  )),
                ],
              ),
              
              pw.Divider(thickness: 0.5),
              
              // Totals
              pw.SizedBox(height: 5),
              _buildBillRow('Subtotal', subtotal, currencyFormat, isBold: false),
              
              if (discounts > 0)
                _buildBillRow('Discounts', discounts, currencyFormat, isBold: false, isNegative: true),
              
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 0.5),
              _buildBillRow('TOTAL', totalAmount, currencyFormat, isBold: true),
              
              pw.SizedBox(height: 20),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    pw.SizedBox(height: 10),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: orderRef,
                      width: 150,
                      height: 50,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'receipt_${date.millisecondsSinceEpoch}');
  }

  static pw.Widget _buildBillRow(String label, double amount, NumberFormat format, {bool isBold = false, bool isNegative = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: isBold ? 10 : 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(
          '${isNegative ? "-" : ""}${format.format(amount)}', 
          style: pw.TextStyle(fontSize: isBold ? 10 : 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)
        ),
      ],
    );
  }
}

class ReceiptItem {
  final String name;
  final double quantity;
  final double price;
  final double total;
  final double discountAmount;
  final String discountType;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.discountAmount = 0.0,
    this.discountType = 'FIXED',
  });
}
