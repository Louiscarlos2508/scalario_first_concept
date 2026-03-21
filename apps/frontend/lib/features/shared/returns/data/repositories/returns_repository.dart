import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReturnsRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  ReturnsRepository({http.Client? httpClient, String? Function()? tokenGetter})
    : _httpClient = httpClient ?? http.Client(),
      _tokenGetter = tokenGetter;

  Map<String, String> _headers({String? tenantId}) {
    String? token;
    try {
      token =
          _tokenGetter?.call() ??
          Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {}
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  /// Search a transaction by receipt number (receiptNumber field = transaction id or metadata).
  Future<Map<String, dynamic>?> searchTransaction({
    required String receiptNumber,
    required String tenantId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/transactions').replace(
      queryParameters: {'receiptNumber': receiptNumber, 'tenantId': tenantId},
    );
    final response = await _httpClient.get(
      uri,
      headers: _headers(tenantId: tenantId),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        return items.first as Map<String, dynamic>;
      }
      return null;
    }
    if (response.statusCode == 404) return null;
    throw Exception('Erreur recherche reçu : ${response.statusCode}');
  }

  /// POST /returns — record a return for a single line.
  Future<Map<String, dynamic>> createReturn({
    required String tenantId,
    required String userId,
    String? originalTxId,
    required String catalogItemId,
    String? variantId,
    required double quantity,
    required double unitPrice,
    required String resolution,
    String? reason,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/returns',
    ).replace(queryParameters: {'tenantId': tenantId, 'userId': userId});
    final body = <String, dynamic>{
      'catalogItemId': catalogItemId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'resolution': resolution,
      'originalTxId': ?originalTxId,
      'variantId': ?variantId,
      if (reason?.isNotEmpty ?? false) 'reason': reason,
    };
    final response = await _httpClient.post(
      uri,
      headers: _headers(tenantId: tenantId),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body);
    throw Exception(
      err['message'] ?? 'Erreur lors du retour : ${response.statusCode}',
    );
  }
}
