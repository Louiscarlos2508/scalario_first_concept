class Promotion {
  final String id;
  final String type; // 'PERCENT', 'BUY_N_GET_M', 'CROSSED_PRICE'
  final String scope; // 'ITEM', 'CATEGORY'
  final String? scopeId;
  final Map<String, dynamic> value;
  final String startDate;
  final String endDate;
  final String status; // 'active', 'inactive'
  final String conflictRule; // 'BEST', 'FIRST'

  const Promotion({
    required this.id,
    required this.type,
    required this.scope,
    this.scopeId,
    required this.value,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.conflictRule,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      type: json['type'] as String,
      scope: json['scope'] as String,
      scopeId: json['scopeId'] as String?,
      value: json['value'] is Map
          ? Map<String, dynamic>.from(json['value'] as Map)
          : {},
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      conflictRule: json['conflictRule'] as String? ?? 'BEST',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'scope': scope,
        'scopeId': scopeId,
        'value': value,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
        'conflictRule': conflictRule,
      };

  /// Human-readable label for the promotion type.
  String get typeLabel {
    switch (type) {
      case 'PERCENT':
        return 'Remise ${value['percent']}%';
      case 'BUY_N_GET_M':
        return '${value['buyN']} achetés = ${value['getM']} offert(s)';
      case 'CROSSED_PRICE':
        return 'Prix barré';
      default:
        return type;
    }
  }

  /// Computed discount amount given [unitPrice] and [quantity].
  /// Returns 0 for BUY_N_GET_M (handled separately as free items).
  double discountAmount(double unitPrice, double quantity) {
    switch (type) {
      case 'PERCENT':
        final pct = (value['percent'] as num?)?.toDouble() ?? 0;
        return unitPrice * (pct / 100);
      case 'CROSSED_PRICE':
        final newPrice = (value['newPrice'] as num?)?.toDouble() ?? unitPrice;
        return (unitPrice - newPrice).clamp(0.0, double.infinity);
      default:
        return 0;
    }
  }
}
