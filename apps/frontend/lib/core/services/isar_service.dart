import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/data/models/order.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [ProductSchema, OrderSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }
}
