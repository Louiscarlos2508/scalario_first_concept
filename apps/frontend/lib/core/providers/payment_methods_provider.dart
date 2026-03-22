import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

/// All payment methods with their French labels.
const kAllPaymentMethods = [
  ('CASH', 'Espèces'),
  ('MOBILE_MONEY', 'Mobile Money'),
  ('CARD', 'Carte bancaire'),
  ('TRANSFER', 'Virement'),
  ('CREDIT', 'Crédit client'),
  ('SPLIT', 'Paiement mixte'),
];

const kDefaultPaymentMethods = ['CASH', 'MOBILE_MONEY'];

String paymentMethodLabel(String code) {
  for (final (c, label) in kAllPaymentMethods) {
    if (c == code) return label;
  }
  return code;
}

/// Enabled payment methods for the current tenant.
/// Falls back to [kDefaultPaymentMethods] on error or while loading.
final enabledPaymentMethodsProvider = FutureProvider<List<String>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return kDefaultPaymentMethods;

  try {
    final token =
        Supabase.instance.client.auth.currentSession?.accessToken ?? '';
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/tenant/payment-methods'),
      headers: ApiConstants.headers(tenantId: tenantId, token: token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['paymentMethods'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      if (list != null && list.isNotEmpty) return list;
    }
  } catch (_) {}
  return kDefaultPaymentMethods;
});
