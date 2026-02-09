import 'package:isar/isar.dart';

part 'order.g.dart';

@collection
class Order {
  Id id = Isar.autoIncrement;

  // Removed Index for Web compatibility 
  // @Index(unique: true, replace: true)
  String uuid = ''; // App-generated UUID

  late double totalAmount;
  late DateTime createdAt;
  
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;
  
  String? tenantId;
  
  List<String>? itemNames; 

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'totalAmount': totalAmount,
      'itemNames': itemNames ?? [],
      'tenantId': tenantId,
    };
  }
}

enum SyncStatus { pending, synced, error }
