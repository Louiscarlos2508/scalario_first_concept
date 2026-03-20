import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

/// AC2 (Story 24-3) — Fetches all active batches with freshness data.
/// Returns list sorted by expiresAt ASC (backend already sorts).
final freshnessProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final uri = Uri.parse('${ApiConstants.baseUrl}/batches/expiring').replace(
    queryParameters: {'tenantId': tenantId, 'days': '90'},
  );
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
  }
  throw Exception('Failed to fetch batches: ${response.statusCode}');
});

/// AC4 (Story 24-3) — Count of urgent batches (freshnessPercent < 50%).
final urgentBatchCountProvider = AutoDisposeFutureProvider<int>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return 0;

  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final uri = Uri.parse(
    '${ApiConstants.baseUrl}/batches/expiring/count',
  ).replace(queryParameters: {'tenantId': tenantId});
  final response = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['urgentCount'] as int? ?? 0;
  }
  return 0;
});
