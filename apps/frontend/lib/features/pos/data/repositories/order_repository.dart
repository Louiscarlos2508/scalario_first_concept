import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/pos/data/models/order.dart';

class OrderRepository {
  final IsarService _isarService;
  final Uuid _uuid = const Uuid();

  OrderRepository(this._isarService);

  Future<void> saveOrder(Order order) async {
    final isar = await _isarService.db;
    order.uuid = order.uuid.isEmpty ? _uuid.v4() : order.uuid;
    order.createdAt = DateTime.now();
    order.syncStatus = SyncStatus.pending;
    
    await isar.writeTxn(() async {
      await isar.orders.put(order);
    });
  }

  Future<List<Order>> getPendingOrders() async {
    final isar = await _isarService.db;
    return await isar.orders.filter().syncStatusEqualTo(SyncStatus.pending).findAll();
  }

  Future<void> markAsSynced(int id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final order = await isar.orders.get(id);
      if (order != null) {
        order.syncStatus = SyncStatus.synced;
        await isar.orders.put(order);
      }
    });
  }
}
