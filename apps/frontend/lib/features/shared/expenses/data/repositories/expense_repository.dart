import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/shared/expenses/data/models/expense.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  ExpenseRepository({http.Client? httpClient, String? Function()? tokenGetter})
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
    return ApiConstants.headers(tenantId: tenantId, token: token);
  }

  /// POST /retail/expenses — creates an expense.
  Future<Expense> create({
    required String tenantId,
    required String label,
    required double amount,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final body = {
      'tenantId': tenantId,
      'label': label,
      'amount': amount,
      'category': category,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/retail/expenses'),
      headers: _authHeaders(tenantId: tenantId),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Expense.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('createExpense failed: ${response.statusCode} — ${response.body}');
  }

  /// GET /retail/expenses?tenantId=&from=&to= — lists non-deleted expenses.
  Future<List<Expense>> list({
    required String tenantId,
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{'tenantId': tenantId};
    if (from != null) {
      params['from'] =
          '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    }
    if (to != null) {
      params['to'] =
          '${to.year}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/retail/expenses')
        .replace(queryParameters: params);

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('listExpenses failed: ${response.statusCode} — ${response.body}');
  }

  /// DELETE /retail/expenses/:id — soft-deletes an expense.
  Future<void> delete(String id, {required String tenantId}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/retail/expenses/$id')
        .replace(queryParameters: {'tenantId': tenantId});

    final response = await _httpClient.delete(
      uri,
      headers: _authHeaders(tenantId: tenantId),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('deleteExpense failed: ${response.statusCode} — ${response.body}');
    }
  }
}
