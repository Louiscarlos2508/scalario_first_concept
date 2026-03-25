import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class InternalRequestsRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  InternalRequestsRepository({
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

  /// POST /internal-requests
  Future<Map<String, dynamic>> create({
    required String catalogItemId,
    required int quantity,
    required String urgency,
    required String tenantId,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/internal-requests'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode({
        'catalogItemId': catalogItemId,
        'quantity': quantity,
        'urgency': urgency,
        'tenantId': tenantId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('create failed: ${response.statusCode} — ${response.body}');
  }

  /// GET /internal-requests
  Future<List<Map<String, dynamic>>> list({
    required String tenantId,
    String? status,
    String? urgency,
  }) async {
    final params = <String, String>{'tenantId': tenantId};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (urgency != null && urgency.isNotEmpty) params['urgency'] = urgency;

    final uri = Uri.parse('${ApiConstants.baseUrl}/internal-requests')
        .replace(queryParameters: params);

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('list failed: ${response.statusCode} — ${response.body}');
  }

  /// POST /internal-requests/:id/prepare
  Future<Map<String, dynamic>> prepare(String id, {required String tenantId}) async {
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/internal-requests/$id/prepare'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode({}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('prepare failed: ${response.statusCode} — ${response.body}');
  }

  /// POST /internal-requests/:id/approve
  Future<Map<String, dynamic>> approve(
    String id, {
    required String tenantId,
    int? quantity,
  }) async {
    final body = <String, dynamic>{};
    if (quantity != null) body['quantity'] = quantity;

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/internal-requests/$id/approve'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('approve failed: ${response.statusCode} — ${response.body}');
  }

  /// POST /internal-requests/:id/reject
  Future<Map<String, dynamic>> reject(
    String id, {
    required String tenantId,
    required String reason,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/internal-requests/$id/reject'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('reject failed: ${response.statusCode} — ${response.body}');
  }
}
