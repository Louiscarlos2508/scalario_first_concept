import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/isar_service.dart';
import '../models/order.dart';

class OrderRepository {
  final IsarService isarService;

  OrderRepository(this.isarService);

  Future<void> createOrder(Order order) async {
    final db = await isarService.db;
    order.uuid = const Uuid().v4();
    order.createdAt = DateTime.now();
    order.status = OrderStatus.pendingSync;

    await db.writeTxn(() async {
      await db.orders.put(order);
    });
  }

  Future<List<Order>> getPendingOrders() async {
    final db = await isarService.db;
    return await db.orders.filter().statusEqualTo(OrderStatus.pendingSync).findAll();
  }
}
