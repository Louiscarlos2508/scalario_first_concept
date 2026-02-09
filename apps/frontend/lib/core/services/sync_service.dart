import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/pos/data/models/product.dart';

class SyncService {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;
  Timer? _syncTimer;

  // Local NestJS backend URL
  static const String _baseUrl = 'http://127.0.0.1:3000';

  SyncService(this._orderRepository, this._productRepository);

  void startSync() {
    _syncTimer?.cancel();
    // Start initial sync
    _performSync();
    
    // Schedule periodic sync
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _performSync();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
  }

  Future<void> _performSync() async {
    await _pushPendingOrders();
    await _pullProducts();
  }

  Future<void> _pushPendingOrders() async {
    final pendingOrders = await _orderRepository.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    for (final order in pendingOrders) {
      try {
        print('Syncing order ${order.uuid} to backend...');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/pos/orders'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(order.toJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _orderRepository.markAsSynced(order.id);
          print('Order ${order.uuid} synced successfully.');
        } else {
          print('Failed to sync order ${order.uuid}: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Failed to sync order ${order.uuid}: $e');
      }
    }
  }

  Future<void> _pullProducts() async {
    try {
      print('Pulling products from backend...');
      
      final response = await http.get(Uri.parse('$_baseUrl/pos/products'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        
        await _productRepository.saveProducts(products);
        print('Products updated locally (Count: ${products.length}).');
      } else {
        print('Failed to pull products: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to pull products: $e');
    }
  }
}
