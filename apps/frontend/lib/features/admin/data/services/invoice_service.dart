import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generates and downloads admin billing invoices (FAC-XXXX) and receipts (REC-XXXX).
class InvoiceService {
  // Noto Sans supporte Unicode complet (em dash, accents, etc.)
  static Future<pw.ThemeData> _theme() async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(base: regular, bold: bold);
  }

  // ── Invoice PDF ─────────────────────────────────────────────────────────────

  static Future<void> generateAndDownloadInvoice(
      Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document(theme: await _theme());
    final invoiceNumber = invoiceData['invoiceNumber'] as String;
    final date = DateTime.tryParse(invoiceData['date'] as String? ?? '') ??
        DateTime.now();
    final tenant = invoiceData['tenant'] as Map<String, dynamic>;
    final lines =
        (invoiceData['lines'] as List).cast<Map<String, dynamic>>();
    final total = (invoiceData['total'] as num).toDouble();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('FACTURE'),
          pw.SizedBox(height: 24),
          _invoiceMeta(invoiceNumber, date),
          pw.SizedBox(height: 20),
          _parties(tenantName: tenant['name'] as String? ?? ''),
          pw.SizedBox(height: 20),
          _linesTable(lines),
          pw.SizedBox(height: 16),
          _totalRow(total),
          pw.SizedBox(height: 24),
          _paymentTerms(),
          pw.Spacer(),
          _signature(),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ── Receipt PDF ─────────────────────────────────────────────────────────────

  static Future<void> generateAndDownloadReceipt(
      Map<String, dynamic> receiptData) async {
    final pdf = pw.Document(theme: await _theme());
    final receiptNumber = receiptData['receiptNumber'] as String;
    final invoiceRef = receiptData['invoiceNumber'] as String?;
    final date = DateTime.tryParse(receiptData['date'] as String? ?? '') ??
        DateTime.now();
    final tenant = receiptData['tenant'] as Map<String, dynamic>;
    final amount = (receiptData['amount'] as num).toDouble();
    final description = receiptData['description'] as String? ?? '';
    final paymentMethod = receiptData['paymentMethod'] as String? ?? '';
    final paymentRef = receiptData['paymentRef'] as String?;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header('REÇU DE PAIEMENT'),
          pw.SizedBox(height: 24),
          _receiptMeta(receiptNumber, date),
          pw.SizedBox(height: 20),
          _parties(tenantName: tenant['name'] as String? ?? ''),
          pw.SizedBox(height: 20),
          _receiptDetail(
            invoiceRef: invoiceRef,
            description: description,
            amount: amount,
            date: date,
            method: paymentMethod,
            ref: paymentRef,
          ),
          pw.SizedBox(height: 24),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Ce reçu confirme la réception du paiement ci-dessus.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Spacer(),
          _signature(),
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  // ── Private builders ────────────────────────────────────────────────────────

  static pw.Widget _header(String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SCALARIO',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Logiciel de caisse & ERP',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text('contact@scalario.app',
                style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _invoiceMeta(String number, DateTime date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('N° $number',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('Date : ${DateFormat('dd/MM/yyyy').format(date)}',
            style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _receiptMeta(String number, DateTime date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('N° $number',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('Date : ${DateFormat('dd/MM/yyyy').format(date)}',
            style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _parties({required String tenantName}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ÉMETTEUR',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text('Scalario',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Ouagadougou, Burkina Faso',
                  style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CLIENT',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600)),
              pw.SizedBox(height: 4),
              pw.Text(tenantName,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _linesTable(List<Map<String, dynamic>> lines) {
    final fmt = NumberFormat('#,###', 'fr_FR');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _cell('Description', header: true),
            _cell('Montant (FCFA)', header: true, right: true),
          ],
        ),
        ...lines.map((l) => pw.TableRow(children: [
              _cell(l['description'] as String? ?? ''),
              _cell(
                  '${fmt.format((l['amount'] as num).toDouble())} FCFA',
                  right: true),
            ])),
      ],
    );
  }

  static pw.Widget _cell(String text,
      {bool header = false, bool right = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 10,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _totalRow(double total) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'TOTAL : ${fmt.format(total)} FCFA',
            style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 13),
          ),
        ),
      ],
    );
  }

  static pw.Widget _receiptDetail({
    String? invoiceRef,
    required String description,
    required double amount,
    required DateTime date,
    required String method,
    String? ref,
  }) {
    final fmt = NumberFormat('#,###', 'fr_FR');
    final methodLabel = switch (method) {
      'mobile_money' => 'Mobile Money',
      'bank_transfer' => 'Virement bancaire',
      'cash' => 'Espèces',
      _ => method,
    };

    final rows = <pw.Widget>[
      _detailRow('Motif', description),
      if (invoiceRef != null) _detailRow('Facture de référence', invoiceRef),
      _detailRow('Montant reçu', '${fmt.format(amount)} FCFA'),
      _detailRow('Date de paiement', DateFormat('dd/MM/yyyy').format(date)),
      _detailRow('Méthode de paiement', methodLabel),
      if (ref != null && ref.isNotEmpty) _detailRow('Référence', ref),
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start, children: rows),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _paymentTerms() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Conditions de paiement',
            style: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Payable à réception.',
            style: const pw.TextStyle(fontSize: 10)),
        pw.Text('Méthodes acceptées : Mobile Money • Virement • Espèces',
            style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static pw.Widget _signature() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Scalario',
                style: pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Container(
              width: 120,
              height: 1,
              color: PdfColors.grey400,
            ),
            pw.SizedBox(height: 2),
            pw.Text('Signature', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }
}
