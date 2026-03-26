import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientOrderRepository {
  final http.Client _httpClient;

  ClientOrderRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  Map<String, String> _headers({String? tenantId}) {
    String? token;
    try {
      token = Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {}
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  Future<List<ClientOrder>> getOrders({
    required String tenantId,
    String? status,
    String? customerId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final params = <String, String>{'tenantId': tenantId};
    if (status != null) params['status'] = status;
    if (customerId != null) params['customerId'] = customerId;
    if (dateFrom != null) params['dateFrom'] = dateFrom.toIso8601String();
    if (dateTo != null) params['dateTo'] = dateTo.toIso8601String();

    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders')
        .replace(queryParameters: params);
    final response = await _httpClient.get(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final items = (body['items'] ?? body) as List<dynamic>;
      return items
          .map((e) => ClientOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erreur chargement commandes : ${response.statusCode}');
  }

  /// PATCH /client-orders/:id/details — edit draft header fields.
  Future<ClientOrder> updateDraft(
    String id, {
    required String tenantId,
    String? notes,
    double? depositAmount,
    DateTime? desiredDeliveryDate,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/details')
        .replace(queryParameters: {'tenantId': tenantId});

    final body = <String, dynamic>{
      'notes': ?notes,
      'depositAmount': ?depositAmount,
      if (desiredDeliveryDate != null)
        'desiredDeliveryDate': desiredDeliveryDate.toIso8601String(),
    };

    final response = await _httpClient.patch(
      uri,
      headers: _headers(tenantId: tenantId),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return ClientOrder.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'updateDraft failed: ${response.statusCode} — ${response.body}');
  }

  Future<void> confirmOrder(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/confirm')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.post(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Erreur confirmation : ${response.statusCode}');
    }
  }

  Future<void> cancelOrder(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/cancel')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.post(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Erreur annulation : ${response.statusCode}');
    }
  }

  Future<ClientOrder> createOrder({
    required String tenantId,
    required String customerId,
    required List<Map<String, dynamic>> lines,
    double? depositAmount,
    String? notes,
    DateTime? desiredDeliveryDate,
  }) async {
    final body = <String, dynamic>{
      'tenantId': tenantId,
      'customerId': customerId,
      'lines': lines,
      'depositAmount': depositAmount,
      'notes': notes,
      'desiredDeliveryDate': desiredDeliveryDate?.toIso8601String(),
    };
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders');
    final response = await _httpClient.post(
      uri,
      headers: _headers(tenantId: tenantId),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return ClientOrder.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    final err = jsonDecode(response.body);
    throw Exception(
        err['message'] ?? 'Erreur création commande : ${response.statusCode}');
  }

  Future<ClientOrderKpis> getKpis({required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/kpis')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.get(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode == 200) {
      return ClientOrderKpis.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Erreur KPI commandes : ${response.statusCode}');
  }

  Future<ClientOrder> getOrder(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.get(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode == 200) {
      return ClientOrder.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Erreur chargement commande : ${response.statusCode}');
  }

  Future<void> prepareOrder(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/prepare')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.post(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Erreur préparation : ${response.statusCode}');
    }
  }

  Future<void> markReady(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/mark-ready')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.post(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Erreur mark-ready : ${response.statusCode}');
    }
  }

  Future<ClientOrder> deliverOrder(
    String id, {
    required String tenantId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/deliver')
        .replace(queryParameters: {'tenantId': tenantId});
    final response = await _httpClient.post(
      uri,
      headers: _headers(tenantId: tenantId),
      body: jsonEncode({'lines': lines}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ClientOrder.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    final err = jsonDecode(response.body);
    throw Exception(
        err['message'] ?? 'Erreur livraison : ${response.statusCode}');
  }

  Future<void> invoiceOrder(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/invoice')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.post(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Erreur facturation : ${response.statusCode}');
    }
  }

  Future<void> payOrder(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/client-orders/$id/pay')
        .replace(queryParameters: {'tenantId': tenantId});
    final response =
        await _httpClient.post(uri, headers: _headers(tenantId: tenantId));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Erreur paiement : ${response.statusCode}');
    }
  }
}
