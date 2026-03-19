import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseOrdersRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  PurchaseOrdersRepository({
    http.Client? httpClient,
    String? Function()? tokenGetter,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenGetter = tokenGetter;

  Map<String, String> _authHeaders({String? tenantId}) {
    String? token;
    try {
      token = _tokenGetter?.call() ??
          Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {}
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  /// GET /purchase-orders?tenantId=&status=
  Future<List<PurchaseOrderLocal>> listOrders({
    required String tenantId,
    String? status,
  }) async {
    final params = <String, String>{'tenantId': tenantId};
    if (status != null && status.isNotEmpty) params['status'] = status;

    final uri = Uri.parse('${ApiConstants.baseUrl}/purchase-orders')
        .replace(queryParameters: params);

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>? ?? []);
      return items
          .map((e) => PurchaseOrderLocal.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        'listOrders failed: ${response.statusCode} — ${response.body}');
  }

  /// GET /purchase-orders/:id?tenantId=
  Future<PurchaseOrderLocal> getOrder(String id,
      {required String tenantId}) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/purchase-orders/$id').replace(
      queryParameters: {'tenantId': tenantId},
    );

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode == 200) {
      return PurchaseOrderLocal.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'getOrder failed: ${response.statusCode} — ${response.body}');
  }

  /// POST /purchase-orders
  Future<PurchaseOrderLocal> createOrder({
    required String tenantId,
    String? supplierId,
    DateTime? expectedDate,
    String? notes,
    required List<Map<String, dynamic>> lines,
  }) async {
    final body = <String, dynamic>{
      'tenantId': tenantId,
      'lines': lines,
      if (supplierId != null && supplierId.isNotEmpty)
        'supplierId': supplierId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (expectedDate != null)
        'expectedDate':
            '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}',
    };

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/purchase-orders'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PurchaseOrderLocal.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'createOrder failed: ${response.statusCode} — ${response.body}');
  }

  /// PATCH /purchase-orders/:id?tenantId=
  Future<PurchaseOrderLocal> updateStatus(
      String id, String status, String tenantId) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/purchase-orders/$id').replace(
      queryParameters: {'tenantId': tenantId},
    );

    final response = await _httpClient.patch(
      uri,
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return PurchaseOrderLocal.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'updateStatus failed: ${response.statusCode} — ${response.body}');
  }

  /// POST /purchase-orders/:id/receive
  Future<PurchaseOrderLocal> receiveOrder(
      String id, List<Map<String, dynamic>> lines, String tenantId) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/purchase-orders/$id/receive').replace(
      queryParameters: {'tenantId': tenantId},
    );

    final response = await _httpClient.post(
      uri,
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode({'lines': lines}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return PurchaseOrderLocal.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'receiveOrder failed: ${response.statusCode} — ${response.body}');
  }

  /// GET /purchase-orders/stats?tenantId=
  Future<Map<String, int>> getStats(String tenantId) async {
    final uri =
        Uri.parse('${ApiConstants.baseUrl}/purchase-orders/stats').replace(
      queryParameters: {'tenantId': tenantId},
    );

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'confirmed': data['confirmed'] as int? ?? 0,
        'partiallyReceived': data['partiallyReceived'] as int? ?? 0,
        'total': data['total'] as int? ?? 0,
      };
    }
    throw Exception(
        'getStats failed: ${response.statusCode} — ${response.body}');
  }

  /// GET /contacts?tenantId=&contactType=supplier
  Future<List<Map<String, dynamic>>> listSuppliers(String tenantId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/contacts').replace(
      queryParameters: {'tenantId': tenantId, 'contactType': 'supplier'},
    );

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw Exception(
        'listSuppliers failed: ${response.statusCode} — ${response.body}');
  }
}
