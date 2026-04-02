import 'package:isar/isar.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/models/parked_cart.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/core/models/sync_metadata.dart';
import 'package:frontend/core/models/sync_status.dart';
import 'package:frontend/features/retail/pos/data/models/category.dart';
import 'package:frontend/features/shared/inventory/data/models/inventory_movement_local.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = initDb();
  }

  @visibleForTesting
  @protected
  Future<Isar> initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      // WAL: Isar 3.x uses WAL by default — relaxedDurability omitted intentionally.
      // Committed writes survive unexpected process termination (AC1, Story 8.4).
      return await Isar.open(
        [ProductSchema, OrderSchema, PosSessionSchema, ParkedCartSchema, CustomerSchema, SyncMetadataSchema, CategorySchema, InventoryMovementLocalSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  // --- Product Methods ---

  Future<List<Product>> getAllProducts() async {
    final isar = await db;
    return await isar.products.where().findAll();
  }

  Future<void> saveProducts(List<Product> products) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.products.putAll(products);
    });
  }

  Future<void> cleanProducts() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.products.clear();
    });
  }

  // --- Order Methods ---

  Future<void> saveOrder(Order order) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.orders.put(order);
    });
  }

  Future<List<Order>> getPendingOrders() async {
    final isar = await db;
    return await isar.orders
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
  }

  // --- Parked Cart Methods ---

  Future<List<ParkedCart>> getAllParkedCarts() async {
    final isar = await db;
    return await isar.parkedCarts.where().findAll();
  }

  Future<void> saveParkedCart(ParkedCart cart) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.parkedCarts.put(cart);
    });
  }

  Future<void> deleteParkedCart(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.parkedCarts.delete(id);
    });
  }

  // --- Customer Methods ---

  Future<List<Customer>> getAllCustomers() async {
    final isar = await db;
    return await isar.customers.where().findAll();
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.customers.putAll(customers);
    });
  }

  Future<void> saveCustomer(Customer customer) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.customers.put(customer);
    });
  }

  Future<void> cleanCustomers() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.customers.clear();
    });
  }

  Future<void> incrementCustomerBalance(String remoteId, double amount) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final customer = await isar.customers.filter().remoteIdEqualTo(remoteId).findFirst();
      if (customer != null) {
        customer.balance += amount;
        await isar.customers.put(customer);
      }
    });
  }

  // --- Category Methods ---

  Future<void> clearCategories() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categorys.clear();
    });
  }

  Future<void> saveCategories(List<dynamic> categories) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categorys.putAll(List<Category>.from(categories));
    });
  }

  // --- Sync Metadata Methods ---

  Future<DateTime?> getLastSync(String key) async {
    final isar = await db;
    final meta = await isar.syncMetadatas.filter().keyEqualTo(key).findFirst();
    return meta?.lastSync;
  }

  Future<void> updateLastSync(String key, DateTime timestamp) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final existing =
          await isar.syncMetadatas.filter().keyEqualTo(key).findFirst();
      if (existing != null) {
        existing.lastSync = timestamp;
        await isar.syncMetadatas.put(existing);
      } else {
        await isar.syncMetadatas
            .put(SyncMetadata(key: key, lastSync: timestamp));
      }
    });
  }

  // --- Fix 5: Schema Version Helpers ---
  // Le schemaVersion est encodé comme millisecondsSinceEpoch dans le champ
  // lastSync d'une entrée SyncMetadata dédiée (clé '__schema_v__').
  // Migration additive — pas de nouveau champ Isar, pas de build_runner.

  static const _schemaVersionKey = '__schema_v__';

  /// Retourne la version de schéma stockée localement (0 si absente).
  Future<int> getSchemaVersion() async {
    final meta = await getLastSync(_schemaVersionKey);
    return meta?.millisecondsSinceEpoch ?? 0;
  }

  /// Stocke [version] comme version de schéma locale.
  Future<void> updateSchemaVersion(int version) async {
    await updateLastSync(
      _schemaVersionKey,
      DateTime.fromMillisecondsSinceEpoch(version),
    );
  }
}
