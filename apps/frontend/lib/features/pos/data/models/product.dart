import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String sku;

  late String name;

  late double price;

  late int stock;

  // Sync metadata
  DateTime? lastSyncedAt;
}
