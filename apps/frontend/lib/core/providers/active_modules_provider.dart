import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_state.dart';
import '../constants/api_constants.dart';

String _token() {
  try {
    return Supabase.instance.client.auth.currentSession?.accessToken ?? '';
  } catch (_) {
    return '';
  }
}

/// Set of active module codes for the current tenant.
/// Automatically refreshes when [activeTenantProvider] changes.
final activeModulesProvider = FutureProvider<Set<String>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return {};

  final token = _token();
  if (token.isEmpty) return {};

  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/tenant-modules?tenantId=$tenantId'),
    headers: ApiConstants.headers(token: token),
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final codes = List<String>.from(body['modules'] as List? ?? []);
    return codes.toSet();
  }
  // On error (network, 403, etc.) → show all tabs rather than crash
  return {};
});
