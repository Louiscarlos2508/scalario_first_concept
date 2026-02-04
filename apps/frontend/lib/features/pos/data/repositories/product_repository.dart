import 'package:isar/isar.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/pos/data/models/product.dart';

class ProductRepository {
  final IsarService _isarService;

  ProductRepository(this._isarService);

  Future<List<Product>> getProducts() async {
    final isar = await _isarService.db;
    return await isar.products.where().findAll();
  }

  Future<void> saveProducts(List<Product> products) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.products.putAll(products);
    });
  }

  Future<void> clearProducts() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.products.clear();
    });
  }
}
