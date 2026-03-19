import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/utils/conflict_resolution.dart';

Map<String, String> _authHeaders({String? tenantId, String? token}) {
  final accessToken =
      token ?? Supabase.instance.client.auth.currentSession?.accessToken;
  return {
    'Content-Type': 'application/json',
    if (tenantId != null) 'x-tenant-id': tenantId,
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
}

class ProductRepository {
  final IsarService _isarService;

  ProductRepository(this._isarService);

  Future<List<Product>> getProducts({
    String? categoryId,
    String? tenantId,
  }) async {
    final isar = await _isarService.db;
    final query = isar.products.where();

    if (tenantId != null) {
      return await query
          .filter()
          .tenantIdEqualTo(tenantId)
          .optional(categoryId != null, (q) => q.categoryIdEqualTo(categoryId))
          .findAll();
    }

    if (categoryId != null) {
      return await query.filter().categoryIdEqualTo(categoryId).findAll();
    }
    return await query.findAll();
  }

  Future<void> saveProducts(List<Product> products) async {
    await _isarService.saveProducts(products);
  }

  Future<void> clearProducts() async {
    await _isarService.cleanProducts();
  }

  Future<void> upsertProducts(List<Product> products) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      for (final product in products) {
        final existing = await isar.products
            .filter()
            .remoteIdEqualTo(product.remoteId)
            .findFirst();

        if (existing != null) {
          // tombstoning: if marked as deleted in cloud, delete locally
          if (product.isDeleted) {
            await isar.products.delete(existing.id);
            continue;
          }

          // Conflict Resolution: Last-Write-Wins from Cloud
          if (!shouldOverwrite(existing.lastUpdated, product.lastUpdated)) {
            print('[ProductRepo] Skipping stale update for ${product.name}');
            continue;
          }
          product.id = existing.id;
        } else if (product.isDeleted) {
          // If deleted in cloud but not local, just skip
          continue;
        }
        await isar.products.put(product);
      }
    });
  }

  Future<void> decrementStock(String productId, double quantity) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final product = await isar.products
          .filter()
          .remoteIdEqualTo(productId)
          .findFirst();
      if (product != null) {
        product.stockQuantity -= quantity;
        await isar.products.put(product);
      }
    });
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final isar = await _isarService.db;
    return await isar.products.filter().barcodeEqualTo(barcode).findFirst();
  }

  Future<Product?> getProductById(String remoteId) async {
    final isar = await _isarService.db;
    return await isar.products.filter().remoteIdEqualTo(remoteId).findFirst();
  }

  Future<void> syncProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pos/products/sync'),
        headers: _authHeaders(tenantId: product.tenantId),
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final syncedProduct = Product.fromJson(data);

        // Update local Isar
        final isar = await _isarService.db;
        await isar.writeTxn(() async {
          // Find by remoteId to replace if exists
          final existing = await isar.products
              .filter()
              .remoteIdEqualTo(syncedProduct.remoteId)
              .findFirst();

          if (existing != null) {
            syncedProduct.id = existing.id;
          }
          await isar.products.put(syncedProduct);
        });
      } else {
        throw Exception('Failed to sync product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing product: $e');
      // For Dashboard CRUD, we want to know if it failed
      rethrow;
    }
  }

  Future<void> deleteProduct(String remoteId) async {
    // For MVP, we might just mark as isDeleted locally and sync later,
    // OR call a DELETE endpoint. Let's stick to local deletion for now
    // and assume the user wants it gone.
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final product = await isar.products
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
      if (product != null) {
        await isar.products.delete(product.id);
      }
    });

    // TODO: Add backend DELETE call if needed
  }

  Future<void> adjustStock({
    required String productId,
    required double quantity,
    required String type,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pos/products/adjust-stock'),
        headers: _authHeaders(),
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
          'type': type,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final updatedProduct = Product.fromJson(data);

        // Update local stock immediately
        final isar = await _isarService.db;
        await isar.writeTxn(() async {
          final existing = await isar.products
              .filter()
              .remoteIdEqualTo(updatedProduct.remoteId)
              .findFirst();
          if (existing != null) {
            existing.stockQuantity = updatedProduct.stockQuantity;
            await isar.products.put(existing);
          }
        });
      } else {
        throw Exception('Failed to adjust stock: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adjusting stock: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProductsRemote({
    String? query,
    int page = 1,
    int limit = 50,
    String? tenantId,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/pos/products').replace(
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          'page': page.toString(),
          'limit': limit.toString(),
          if (tenantId != null) 'tenantId': tenantId,
        },
      );

      final response = await http.get(
        uri,
        headers: _authHeaders(tenantId: tenantId, token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> itemsData = data['items'];
        final items = itemsData.map((json) => Product.fromJson(json)).toList();

        return {
          'items': items,
          'total': data['total'],
          'totalPages': data['totalPages'],
        };
      } else {
        throw Exception(
          'Failed to fetch remote products: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching remote products: $e');
      rethrow;
    }
  }

  Future<void> deleteProductRemote(String remoteId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/pos/products/$remoteId'),
        headers: _authHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete product remotely: ${response.statusCode}',
        );
      }

      // Also delete locally
      await deleteProduct(remoteId);
    } catch (e) {
      print('Error deleting remote product: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getStockAcrossBranches(
    String barcode,
    String userId,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/pos/stock-across-branches',
      ).replace(queryParameters: {'barcode': barcode, 'userId': userId});
      final response = await http.get(uri, headers: _authHeaders());

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to lookup branch stock: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error looking up branch stock: $e');
      rethrow;
    }
  }
}
