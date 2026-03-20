import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A single price history entry.
class PriceHistoryEntry {
  final String id;
  final double price;
  final DateTime effectiveFrom;
  final String? reason;

  const PriceHistoryEntry({
    required this.id,
    required this.price,
    required this.effectiveFrom,
    this.reason,
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      id: json['id'] as String,
      price: (json['price'] as num).toDouble(),
      effectiveFrom: DateTime.parse(json['effectiveFrom']?.toString() ?? json['effective_from'].toString()),
      reason: json['reason'] as String?,
    );
  }
}

/// AC3 (Story 26-5) — Fetches price history for a catalog item.
final priceHistoryProvider = FutureProvider.family<List<PriceHistoryEntry>, String>((ref, catalogItemId) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final uri = Uri.parse('${ApiConstants.baseUrl}/catalog/items/$catalogItemId/price-history')
      .replace(queryParameters: {'tenantId': tenantId});

  final response = await http.get(uri, headers: ApiConstants.headers(token: token, tenantId: tenantId));
  if (response.statusCode != 200) return [];

  final data = jsonDecode(response.body);
  if (data is List) {
    return data.map((e) => PriceHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
});
