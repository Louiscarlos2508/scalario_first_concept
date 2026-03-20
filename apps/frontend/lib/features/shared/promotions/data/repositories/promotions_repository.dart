import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/shared/promotions/data/models/promotion.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PromotionsRepository {
  final http.Client _httpClient;

  PromotionsRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _authHeaders({String? tenantId}) {
    String? token;
    try {
      token = Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {}
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  /// GET /promotions?status=:status
  Future<List<Promotion>> listPromotions(String tenantId,
      {String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final uri = Uri.parse('${ApiConstants.baseUrl}/promotions')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response =
        await _httpClient.get(uri, headers: _authHeaders(tenantId: tenantId));
    if (response.statusCode != 200) {
      throw Exception('Failed to list promotions: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as List;
    return data.map((e) => Promotion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /promotions/active?catalogItemId=:id
  /// Returns null if no active promotion found or on error (offline-safe).
  Future<Promotion?> getActivePromotion(
      String tenantId, String catalogItemId) async {
    try {
      final uri =
          Uri.parse('${ApiConstants.baseUrl}/promotions/active').replace(
        queryParameters: {'catalogItemId': catalogItemId},
      );
      final response = await _httpClient
          .get(uri, headers: _authHeaders(tenantId: tenantId))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as List;
      if (data.isEmpty) return null;
      return Promotion.fromJson(data.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// POST /promotions
  Future<Promotion> createPromotion(
      String tenantId, Map<String, dynamic> dto) async {
    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/promotions'),
      headers: {
        ..._authHeaders(tenantId: tenantId),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dto),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create promotion: ${response.statusCode}');
    }
    return Promotion.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PATCH /promotions/:id
  Future<void> updatePromotion(
      String tenantId, String id, Map<String, dynamic> dto) async {
    final response = await _httpClient.patch(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$id'),
      headers: {
        ..._authHeaders(tenantId: tenantId),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dto),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update promotion');
    }
  }

  /// DELETE /promotions/:id
  Future<void> deletePromotion(String tenantId, String id) async {
    final response = await _httpClient.delete(
      Uri.parse('${ApiConstants.baseUrl}/promotions/$id'),
      headers: _authHeaders(tenantId: tenantId),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete promotion');
    }
  }
}
