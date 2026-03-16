import 'package:isar/isar.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/data/models/parked_cart.dart';
import 'dart:io';

void main() async {
  // Open Isar database
  final dir = Directory('/home/carlos-simpore/.local/share/frontend');
  final isar = await Isar.open(
    [
      ProductSchema,
      OrderSchema,
      PosSessionSchema,
      ParkedCartSchema,
      CustomerSchema,
    ],
    directory: dir.path,
    inspector: false,
  );

  print('=== PRODUCTS ===');
  final products = await isar.products.where().findAll();
  print('Total products: ${products.length}');
  products.take(3).forEach((p) => print('- ${p.name} (${p.remoteId})'));

  print('\n=== ORDERS ===');
  final orders = await isar.orders.where().findAll();
  print('Total orders: ${orders.length}');
  for (var o in orders) {
    print('- Order ${o.uuid}: ${o.totalAmount} (sync: ${o.syncStatus})');
  }

  print('\n=== SESSIONS ===');
  final sessions = await isar.posSessions.where().findAll();
  print('Total sessions: ${sessions.length}');
  for (var s in sessions) {
    print(
      '- Session ${s.uuid}: ${s.status} (userId: ${s.userId}, tenantId: ${s.tenantId})',
    );
  }

  await isar.close();
}
