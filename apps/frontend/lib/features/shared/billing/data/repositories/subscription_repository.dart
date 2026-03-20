import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_constants.dart';

class SubscriptionRepository {
  final http.Client _client;

  SubscriptionRepository({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getMySubscription({
    required String token,
    required String tenantId,
  }) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/settings/billing'),
      headers: ApiConstants.headers(token: token, tenantId: tenantId),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load subscription: HTTP ${response.statusCode}');
  }

  Future<void> requestUpgrade({
    required String token,
    required String tenantId,
    String? message,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/settings/billing/upgrade-request'),
      headers: ApiConstants.headers(token: token, tenantId: tenantId),
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 201) return;
    if (response.statusCode == 409) {
      throw Exception('Une demande a déjà été envoyée dans les dernières 24h');
    }
    throw Exception('Failed to send upgrade request: HTTP ${response.statusCode}');
  }
}
