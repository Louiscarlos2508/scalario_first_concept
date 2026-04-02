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

  /// Fix 3 — Incrémente le compteur de retry persistant d'un ordre.
  /// Retourne le nouveau compte pour que l'appelant décide si [markAsFailed] suit.
  Future<int> incrementRetryCount(String uuid) async {
    final isar = await _isarService.db;
    int newCount = 0;
    await isar.writeTxn(() async {
      final order = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
      if (order != null) {
        order.retryCount += 1;
        newCount = order.retryCount;
        await isar.orders.put(order);
      }
    });
    return newCount;
  }

  /// Fix 3 — Remet à zéro le compteur de retry (appelé sur succès).
  Future<void> resetRetryCount(String uuid) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final order = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
      if (order != null && order.retryCount != 0) {
        order.retryCount = 0;
        await isar.orders.put(order);
      }
    });
  }

  /// Fix 3 — Marque définitivement un ordre comme échoué après [maxRetries].
  /// Contrairement à [markAsError], cet état n'est PAS réinitialisé par
  /// [resetErrorOrders] : seule une action admin explicite peut le retenter.
  Future<void> markAsFailed(String uuid) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final order = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
      if (order != null) {
        order.syncStatus = SyncStatus.failed;
        await isar.orders.put(order);
      }
    });
  }

  /// Fix 3 — Retourne tous les ordres en état [SyncStatus.failed].
  /// Utilisé par l'écran de diagnostic admin.
  Future<List<Order>> getFailedOrders() async {
    final isar = await _isarService.db;
    return await isar.orders
        .filter()
        .syncStatusEqualTo(SyncStatus.failed)
        .findAll();
  }

  /// Fix 3 — Remet un ordre [failed] en [pending] pour un retry manuel admin.
  Future<void> retryFailedOrder(String uuid) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final order = await isar.orders.filter().uuidEqualTo(uuid).findFirst();
      if (order != null) {
        order.syncStatus = SyncStatus.pending;
        await isar.orders.put(order);
      }
    });
  }

  /// Remet en pending les ordres bloqués en error (ex : 401/403 temporaire).
  /// Appelé au refresh de token pour relancer le retry.
  /// Note : les ordres [SyncStatus.failed] ne sont PAS réinitialisés ici.
  Future<void> resetErrorOrders() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final errorOrders = await isar.orders
          .filter()
          .syncStatusEqualTo(SyncStatus.error)
          .findAll();
      for (final order in errorOrders) {
        order.syncStatus = SyncStatus.pending;
        await isar.orders.put(order);
      }
    });
  }

  Future<List<Order>> getOrdersBySession(String sessionId) async {
    final isar = await _isarService.db;
    final all = await isar.orders.where().findAll();
    return all.where((o) => o.sessionId == sessionId).toList();
  }

  Future<List<Order>> getOrdersSince(DateTime from) async {
    final isar = await _isarService.db;
    final all = await isar.orders.where().findAll();
    return all.where((o) => !o.createdAt.isBefore(from)).toList();
  }
}
