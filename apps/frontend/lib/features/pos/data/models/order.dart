import 'package:isar/isar.dart';

part 'order.g.dart';

@collection
class Order {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String uuid = ''; // App-generated UUID

  late double totalAmount;
  late DateTime createdAt;
  
  @Enumerated(EnumType.name)
  SyncStatus syncStatus = SyncStatus.pending;
  
  String? tenantId;
  
  // To simulate items, we could use embedded objects or just a JSON string for MVP
  // For simplicity MVP:
  List<String>? itemNames; 
}

enum SyncStatus { pending, synced, error }
