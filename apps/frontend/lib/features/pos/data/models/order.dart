import 'package:isar/isar.dart';

part 'order.g.dart';

enum OrderStatus {
  pendingSync,
  synced,
}

@collection
class Order {
  Id id = Isar.autoIncrement;

  late String uuid; // Global unique ID for sync

  late DateTime createdAt;

  @Enumerated(EnumType.ordinal)
  late OrderStatus status;

  late double totalAmount;

  late List<OrderItem> items;
}

@embedded
class OrderItem {
  late String productSku;
  late String productName;
  late double quantity;
  late double price;
}
