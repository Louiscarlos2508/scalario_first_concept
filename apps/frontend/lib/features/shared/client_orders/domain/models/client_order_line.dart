class ClientOrderLine {
  final String id;
  final String clientOrderId;
  final String catalogItemId;
  final String? itemName;
  final String? variantId;
  final double quantity;
  final double unitPrice;
  final double deliveredQty;

  const ClientOrderLine({
    required this.id,
    required this.clientOrderId,
    required this.catalogItemId,
    this.itemName,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.deliveredQty,
  });

  factory ClientOrderLine.fromJson(Map<String, dynamic> json) {
    return ClientOrderLine(
      id: json['id'] as String? ?? '',
      clientOrderId: json['clientOrderId'] as String? ?? '',
      catalogItemId: json['catalogItemId'] as String? ?? '',
      itemName: json['itemName'] as String?,
      variantId: json['variantId'] as String?,
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0.0,
      deliveredQty: double.tryParse(json['deliveredQty']?.toString() ?? '0') ?? 0.0,
    );
  }
}
