import 'package:isar/isar.dart';
import 'cart_item.dart';
import 'package:frontend/core/models/sync_status.dart';

part 'order.g.dart';

@collection
class Order {
  Order();

  Id id = Isar.autoIncrement;

  // Removed Index for Web compatibility
  // @Index(unique: true, replace: true)
  String uuid = ''; // App-generated UUID
  late DateTime createdAt;

  late double totalAmount;
  late List<PosCartItem> items;
  String? sessionId;
  String? paymentMethod;
  String? paymentSplits; // JSON string of Map<String, double>
  String? customerId; // Remote UUID
  String? tenantId;

  // Transaction + RetailSale shape from POST /retail/sales response (added Story 8.2)
  String? receiptNumber;
  String? lifecycleType; // default: 'completed'
  String? userId;

  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'totalAmount': totalAmount,
      'items': items.map((i) => i.toJson()).toList(),
      'sessionId': sessionId,
      'paymentMethod': paymentMethod,
      'payment_splits': paymentSplits,
      'customer_id': customerId,
      'tenantId': tenantId,
      'syncStatus': syncStatus.name,
      'createdAt': createdAt.toIso8601String(),
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      if (lifecycleType != null) 'lifecycleType': lifecycleType,
      if (userId != null) 'userId': userId,
    };
  }

  /// Populate server-assigned fields after a successful POST /retail/sales response.
  factory Order.fromServerResponse(Map<String, dynamic> json) {
    return Order()
      ..uuid = json['uuid']?.toString() ?? ''
      ..totalAmount = _toDouble(json['totalAmount'] ?? json['total_amount'])
      ..receiptNumber =
          json['receiptNumber']?.toString() ?? json['receipt_number']?.toString()
      ..lifecycleType = json['lifecycleType']?.toString() ??
          json['lifecycle_type']?.toString() ??
          'completed'
      ..userId = json['userId']?.toString() ?? json['user_id']?.toString()
      ..sessionId =
          json['sessionId']?.toString() ?? json['session_id']?.toString()
      ..syncStatus = SyncStatus.synced
      ..items = []
      ..createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
