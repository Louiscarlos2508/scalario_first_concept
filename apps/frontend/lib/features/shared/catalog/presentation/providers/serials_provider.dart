import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// A single serial record from the backend.
class SerialRecord {
  final String id;
  final String serial;
  final String catalogItemId;
  final DateTime? soldAt;
  final DateTime? warrantyUntil;
  final DateTime createdAt;

  const SerialRecord({
    required this.id,
    required this.serial,
    required this.catalogItemId,
    this.soldAt,
    this.warrantyUntil,
    required this.createdAt,
  });

  factory SerialRecord.fromJson(Map<String, dynamic> json) {
    return SerialRecord(
      id: json['id'] as String,
      serial: json['serial'] as String,
      catalogItemId: json['catalog_item_id'] ?? json['catalogItemId'] as String,
      soldAt: json['sold_at'] != null ? DateTime.tryParse(json['sold_at'].toString()) : null,
      warrantyUntil: json['warranty_until'] != null ? DateTime.tryParse(json['warranty_until'].toString()) : null,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Fetches paginated serial records for a catalog item.
final serialsProvider = FutureProvider.family<List<SerialRecord>, String>((ref, catalogItemId) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  final uri = Uri.parse('${ApiConstants.baseUrl}/catalog/$catalogItemId/serials?tenantId=$tenantId&limit=50');

  final response = await http.get(uri, headers: ApiConstants.headers(token: token, tenantId: tenantId));

  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final items = data['items'] as List<dynamic>? ?? [];
  return items.map((e) => SerialRecord.fromJson(e as Map<String, dynamic>)).toList();
});
