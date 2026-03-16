class SalesStat {
  final DateTime day;
  final double revenue;
  final int orderCount;

  SalesStat({
    required this.day,
    required this.revenue,
    required this.orderCount,
  });

  factory SalesStat.fromJson(Map<String, dynamic> json) {
    return SalesStat(
      day: DateTime.parse(json['day']),
      revenue: _toDouble(json['revenue']),
      orderCount: json['orderCount'] ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
