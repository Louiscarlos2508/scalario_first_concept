import 'package:isar/isar.dart';
import 'cart_item.dart';

part 'parked_cart.g.dart';

@collection
class ParkedCart {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime createdAt;
  late double totalAmount;
  late List<PosCartItem> items;
  String? paymentMethod;
}
