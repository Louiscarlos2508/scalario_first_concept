import 'package:isar/isar.dart';

part 'product.g.dart';

@collection
class Product {
  Id id = Isar.autoIncrement; // local ID

  @Index(unique: true, replace: true)
  String? remoteId; // UUID from Supabase

  late String name;
  late double price;
  String? category;
  double stockQuantity = 0;
  String? tenantId;
}
