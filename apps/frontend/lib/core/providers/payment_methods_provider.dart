import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class PaymentMethod {
  final String code;
  final String label;

  const PaymentMethod(this.code, this.label);

  /// Parses either a legacy plain string ("CASH") or a full object
  /// ({"code":"ORANGE_MONEY","label":"Orange Money"}).
  factory PaymentMethod.fromJson(dynamic json) {
    if (json is String) {
      return PaymentMethod(json, _builtinLabel(json) ?? _formatCode(json));
    }
    final map = json as Map<String, dynamic>;
    final code = map['code'] as String;
    return PaymentMethod(
      code,
      map['label'] as String? ?? _builtinLabel(code) ?? _formatCode(code),
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'label': label};

  @override
  bool operator ==(Object other) =>
      other is PaymentMethod && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Formats an unknown code for display: ORANGE_MONEY → "Orange Money"
String _formatCode(String code) => code
    .split('_')
    .map((w) => w.isEmpty
        ? ''
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');

String? _builtinLabel(String code) {
  for (final m in kBuiltinPaymentMethods) {
    if (m.code == code) return m.label;
  }
  return null;
}

// ── Built-in methods ──────────────────────────────────────────────────────────

/// Fixed methods shown as toggles in settings. Always in this order.
const kBuiltinPaymentMethods = [
  PaymentMethod('CASH', 'Espèces'),
  PaymentMethod('MOBILE_MONEY', 'Mobile Money'),
  PaymentMethod('CARD', 'Carte bancaire'),
  PaymentMethod('TRANSFER', 'Virement'),
  PaymentMethod('CREDIT', 'Crédit client'),
  PaymentMethod('SPLIT', 'Paiement mixte'),
];

const kBuiltinCodes = {
  'CASH', 'MOBILE_MONEY', 'CARD', 'TRANSFER', 'CREDIT', 'SPLIT'
};

const kDefaultPaymentMethods = [
  PaymentMethod('CASH', 'Espèces'),
  PaymentMethod('MOBILE_MONEY', 'Mobile Money'),
];

// ── Backward-compat label lookup ──────────────────────────────────────────────
/// Used by z_report_service, session_close_screen, etc. (non-Riverpod).
/// For unknown codes (custom methods), formats the code as title case.
String paymentMethodLabel(String code) =>
    _builtinLabel(code) ?? _formatCode(code);

// ── Provider ──────────────────────────────────────────────────────────────────

final enabledPaymentMethodsProvider =
    FutureProvider<List<PaymentMethod>>((ref) async {
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
          ?.map(PaymentMethod.fromJson)
          .toList();
      if (list != null && list.isNotEmpty) return list;
    }
  } catch (_) {}
  return kDefaultPaymentMethods;
});
