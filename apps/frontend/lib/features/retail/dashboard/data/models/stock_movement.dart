import 'package:isar/isar.dart';

part 'stock_movement.g.dart';

@collection
class StockMovement {
  Id id = Isar.autoIncrement;

  @Index()
  late String productId;
  late double quantity;
  late String type; // IN, OUT, ADJUSTMENT
  String? reason;
  late DateTime createdAt;
  late String tenantId;

  StockMovement();

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    return StockMovement()
      ..productId = json['productId']?.toString() ?? json['product_id']?.toString() ?? ''
      ..quantity = (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : double.parse(json['quantity']?.toString() ?? '0')
      ..type = json['type']?.toString() ?? 'ADJUSTMENT'
      ..reason = json['reason']?.toString()
      ..createdAt = DateTime.parse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? DateTime.now().toIso8601String())
      ..tenantId = json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? '';
  }
}
