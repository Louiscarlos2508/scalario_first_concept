import 'package:isar/isar.dart';
import 'cart_item.dart';
import 'package:frontend/core/models/sync_status.dart';

part 'order.g.dart';

@collection
class Order {
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
    };
  }
}
