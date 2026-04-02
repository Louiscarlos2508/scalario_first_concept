/// Données du reçu — format neutre utilisé par tous les printers.
class ReceiptData {
  final String shopName;
  final String documentType;
  final DateTime date;
  final String orderRef;
  final String paymentMethod;
  final String? customerName;
  final List<ReceiptLineItem> items;
  final double totalAmount;
  final double subtotal;
  final double discounts;

  const ReceiptData({
    required this.shopName,
    this.documentType = 'receipt',
    required this.date,
    required this.orderRef,
    required this.paymentMethod,
    this.customerName,
    required this.items,
    required this.totalAmount,
    required this.subtotal,
    this.discounts = 0,
  });
}

class ReceiptLineItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;

  const ReceiptLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}
