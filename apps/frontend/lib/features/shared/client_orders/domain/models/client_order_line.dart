class ClientOrderLine {
  final String id;
  final String clientOrderId;
  final String catalogItemId;
  final String? variantId;
  final double quantity;
  final double unitPrice;
  final double deliveredQty;

  const ClientOrderLine({
    required this.id,
    required this.clientOrderId,
    required this.catalogItemId,
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
      variantId: json['variantId'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      deliveredQty: (json['deliveredQty'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
