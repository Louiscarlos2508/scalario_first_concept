import 'dart:async';
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/pos/data/models/product.dart';

class SyncService {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;
  Timer? _syncTimer;

  SyncService(this._orderRepository, this._productRepository);

  void startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _pushPendingOrders();
      _pullProducts();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
  }

  Future<void> _pushPendingOrders() async {
    final pendingOrders = await _orderRepository.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    for (final order in pendingOrders) {
      try {
        // TODO: Replace with actual backend call
        print('Syncing order ${order.uuid} to backend...');
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network
        
        await _orderRepository.markAsSynced(order.id);
        print('Order ${order.uuid} synced.');
      } catch (e) {
        print('Failed to sync order ${order.uuid}: $e');
      }
    }
  }

  Future<void> _pullProducts() async {
    try {
      // TODO: Replace with actual backend call
      print('Pulling products from backend...');
      await Future.delayed(const Duration(milliseconds: 500)); 
      
      // Mock Data
      final products = [
        Product()
          ..name = 'Coca Cola'
          ..price = 500
          ..category = 'Drinks'
          ..remoteId = 'uuid-1',
        Product()
          ..name = 'Sandwich'
          ..price = 1500
          ..category = 'Food'
          ..remoteId = 'uuid-2',
      ];
      
      await _productRepository.saveProducts(products);
      print('Products updated locally.');
    } catch (e) {
      print('Failed to pull products: $e');
    }
  }
}
