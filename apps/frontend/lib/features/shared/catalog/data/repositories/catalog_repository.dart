import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;
  final IsarService? _isarService;

  CatalogRepository({
    http.Client? httpClient,
    String? Function()? tokenGetter,
    IsarService? isarService,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenGetter = tokenGetter,
        _isarService = isarService;

  Map<String, String> _authHeaders({String? tenantId}) {
    String? token;
    try {
      token = _tokenGetter?.call() ??
          Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      // Supabase not initialized in test environment — no auth header
    }
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  /// POST /catalog/items — creates a catalog item.
  Future<Map<String, dynamic>> createItem({
    required String name,
    required double price,
    required String tenantId,
    String? categoryId,
    String? barcode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'price': price,
      'tenantId': tenantId,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
    };

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/catalog/items'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('createItem failed: ${response.statusCode} — ${response.body}');
  }

  /// Reads products from local Isar database filtered by tenantId.
  /// Returns a list of maps with keys: id, name, price, barcode, stockQuantity.
  Future<List<Map<String, dynamic>>> getProducts({required String tenantId}) async {
    if (_isarService == null) return [];
    final isar = await _isarService.db;
    final allProducts = await isar.products.where().findAll();
    final products = allProducts.where((p) => p.tenantId == tenantId).toList();
    return products.map((p) => <String, dynamic>{
      'id': p.remoteId ?? p.id.toString(),
      'name': p.name,
      'price': p.price,
      'barcode': p.barcode,
      'stockQuantity': p.stockQuantity,
      'categoryId': p.categoryId,
      'tenantId': p.tenantId,
    }).toList();
  }

  /// PUT /catalog/items/:id — updates a catalog item.
  Future<void> updateItem({
    required String id,
    required String name,
    required double price,
    required String tenantId,
    String? categoryId,
    String? barcode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'price': price,
      'tenantId': tenantId,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
    };
    final response = await _httpClient.put(
      Uri.parse('${ApiConstants.baseUrl}/catalog/items/$id'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('updateItem failed: ${response.statusCode} — ${response.body}');
    }
  }

  /// DELETE /catalog/items/:id — deletes a catalog item.
  Future<void> deleteItem({required String id, required String tenantId}) async {
    final response = await _httpClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/catalog/items/$id'),
      headers: _authHeaders(tenantId: tenantId),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('deleteItem failed: ${response.statusCode} — ${response.body}');
    }
  }

  /// GET /catalog/items?tenantId= — lists catalog items.
  Future<List<Map<String, dynamic>>> listItems({required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/catalog/items')
        .replace(queryParameters: {'tenantId': tenantId});

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      // Some backends wrap in {items: [...]}
      final items = (data as Map<String, dynamic>)['items'] as List<dynamic>?;
      return (items ?? []).cast<Map<String, dynamic>>();
    }
    throw Exception('listItems failed: ${response.statusCode} — ${response.body}');
  }
}
