import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class CatalogRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  CatalogRepository({http.Client? httpClient, String? Function()? tokenGetter})
      : _httpClient = httpClient ?? http.Client(),
        _tokenGetter = tokenGetter;

  Map<String, String> _authHeaders({String? tenantId}) {
    String? token;
    try {
      token = _tokenGetter?.call() ??
          Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      // Supabase not initialized in test environment — no auth header
    }
    return {
      'Content-Type': 'application/json',
      if (tenantId != null) 'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
