import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationsRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  ReservationsRepository({
    http.Client? httpClient,
    String? Function()? tokenGetter,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenGetter = tokenGetter;

  Map<String, String> _headers({String? tenantId}) {
    String? token;
    try {
      token = _tokenGetter?.call() ??
          Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {}
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  Future<Map<String, dynamic>> createReservation({
    required String tenantId,
    required String userId,
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double depositAmount,
    required String paymentMethod,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reservations').replace(
      queryParameters: {'tenantId': tenantId, 'userId': userId},
    );
    final body = {
      'customerId': customerId,
      'items': items,
      'totalAmount': totalAmount,
      'depositAmount': depositAmount,
      'paymentMethod': paymentMethod,
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
    throw Exception(err['message'] ?? 'Erreur lors de la réservation : ${response.statusCode}');
  }

  Future<Map<String, dynamic>> listReservations({
    required String tenantId,
    String? status,
    String? customerId,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{'tenantId': tenantId, 'page': '$page', 'limit': '$limit'};
    if (status != null) params['status'] = status;
    if (customerId != null) params['customerId'] = customerId;

    final uri = Uri.parse('${ApiConstants.baseUrl}/reservations').replace(queryParameters: params);
    final response = await _httpClient.get(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Erreur chargement réservations : ${response.statusCode}');
  }

  Future<Map<String, dynamic>> completeReservation({
    required String tenantId,
    required String id,
    required String paymentMethod,
    required double amount,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reservations/$id/complete').replace(
      queryParameters: {'tenantId': tenantId},
    );
    final response = await _httpClient.patch(
      uri,
      headers: _headers(tenantId: tenantId),
      body: jsonEncode({'paymentMethod': paymentMethod, 'amount': amount}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur complétion : ${response.statusCode}');
  }

  Future<Map<String, dynamic>> cancelReservation({
    required String tenantId,
    required String userId,
    required String role,
    required String id,
    required String depositResolution,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reservations/$id/cancel').replace(
      queryParameters: {'tenantId': tenantId, 'userId': userId, 'role': role},
    );
    final response = await _httpClient.patch(
      uri,
      headers: _headers(tenantId: tenantId),
      body: jsonEncode({'depositResolution': depositResolution}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur annulation : ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getKpi({required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/reservations/kpi').replace(
      queryParameters: {'tenantId': tenantId},
    );
    final response = await _httpClient.get(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception('Erreur KPI réservations : ${response.statusCode}');
  }
}
