import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class StockAlertsRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  StockAlertsRepository({
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

  /// GET /stock-alerts?tenantId=&limit=&offset=
  Future<List<Map<String, dynamic>>> getAlerts({
    required String tenantId,
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/stock-alerts').replace(
      queryParameters: {
        'tenantId': tenantId,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data.cast<Map<String, dynamic>>();
      return [];
    }
    throw Exception('getAlerts failed: ${response.statusCode}');
  }

  /// GET /stock-alerts/count?tenantId=
  Future<int> getCount({required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/stock-alerts/count').replace(
      queryParameters: {'tenantId': tenantId},
    );
    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['criticalCount'] as num?)?.toInt() ?? 0;
    }
    throw Exception('getCount failed: ${response.statusCode}');
  }
}
