import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/core/models/sync_status.dart';

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
    return _isarService.getPendingOrders();
  }

  Future<void> markAsSynced(String uuid) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final order = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
      if (order != null) {
        order.syncStatus = SyncStatus.synced;
        await isar.orders.put(order);
      }
    });
  }

  Future<void> markAsError(String uuid) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final order = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
      if (order != null) {
        order.syncStatus = SyncStatus.error;
        await isar.orders.put(order);
      }
    });
  }

  Future<List<Order>> getOrdersBySession(String sessionId) async {
    final isar = await _isarService.db;
    return await isar.orders.filter().sessionIdEqualTo(sessionId).findAll();
  }
}
