import 'package:isar/isar.dart';
import '../../../../core/services/isar_service.dart';
import '../models/product.dart';

class ProductRepository {
  final IsarService isarService;

  ProductRepository(this.isarService);

  Future<void> addProduct(Product product) async {
    final db = await isarService.db;
    await db.writeTxn(() async {
      await db.products.put(product);
    });
  }

  Future<List<Product>> getAllProducts() async {
    final db = await isarService.db;
    return await db.products.where().findAll();
  }
}
