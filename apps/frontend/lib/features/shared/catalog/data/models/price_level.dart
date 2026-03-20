class PriceLevel {
  final String id;
  final String catalogItemId;
  final String levelCode;
  final String label;
  final double price;
  final int? minQty;
  final List<String> customerTypes;

  const PriceLevel({
    required this.id,
    required this.catalogItemId,
    required this.levelCode,
    required this.label,
    required this.price,
    this.minQty,
    this.customerTypes = const [],
  });

  factory PriceLevel.fromJson(Map<String, dynamic> json) {
    return PriceLevel(
      id: json['id'].toString(),
      catalogItemId: (json['catalogItemId'] ?? json['catalog_item_id']).toString(),
      levelCode: json['levelCode'] ?? json['level_code'],
      label: json['label'],
      price: _toDouble(json['price']),
      minQty: json['minQty'] as int? ?? json['min_qty'] as int?,
      customerTypes: (json['customerTypes'] ?? json['customer_types'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'levelCode': levelCode,
        'label': label,
        'price': price,
        if (minQty != null) 'minQty': minQty,
        'customerTypes': customerTypes,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
