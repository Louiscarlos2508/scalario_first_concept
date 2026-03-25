import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

/// FR87 — Emplacements de perte configurables par tenant.
/// Retourne [] si le tenant n'en a pas configuré (champ optionnel).
final lossLocationsProvider = FutureProvider<List<String>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  try {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tenant/loss-locations'),
      headers: ApiConstants.headers(tenantId: tenantId, token: token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['locations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }
  } catch (_) {}
  return [];
});
