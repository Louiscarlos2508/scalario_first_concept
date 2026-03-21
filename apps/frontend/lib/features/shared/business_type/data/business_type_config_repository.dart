import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// Default screens per role when config is unavailable (fallback).
const _kDefaultScreens = <String, List<String>>{
  'owner': ['backoffice', 'pos'],
  'manager': ['backoffice_restricted'],
  'commercial': ['pos', 'losses', 'transfers', 'stock_view', 'daily_sales'],
  'cashier': ['pos'],
};

class BusinessTypeConfig {
  final String code;
  final String name;
  final Map<String, dynamic> defaultFlags;
  final List<String> visibleSections;
  final List<String> suggestedCategories;
  // Epic 30 — FR111: role display labels (e.g. {"commercial": "Vendeur"})
  final Map<String, dynamic> roleLabels;
  // Epic 30 — FR109: delivery document type ('receipt' | 'delivery_note' | 'invoice')
  final String documentType;
  // Epic 30 — FR112: screen access per role
  final Map<String, List<String>> roleScreenAccess;

  const BusinessTypeConfig({
    required this.code,
    required this.name,
    required this.defaultFlags,
    required this.visibleSections,
    required this.suggestedCategories,
    this.roleLabels = const {},
    this.documentType = 'receipt',
    this.roleScreenAccess = const {},
  });

  /// Returns the list of allowed screens for [role].
  /// Falls back to sensible defaults if roleScreenAccess is not configured.
  List<String> screensForRole(String role) {
    if (roleScreenAccess.containsKey(role)) {
      return roleScreenAccess[role]!;
    }
    return _kDefaultScreens[role] ?? ['pos'];
  }

  bool canAccess(String role, String screen) =>
      screensForRole(role).contains(screen);

  factory BusinessTypeConfig.fromJson(Map<String, dynamic> json) {
    final rawAccess = json['roleScreenAccess'] as Map<String, dynamic>? ?? {};
    final roleScreenAccess = rawAccess.map(
      (k, v) => MapEntry(
        k,
        (v as List<dynamic>).map((e) => e as String).toList(),
      ),
    );
    return BusinessTypeConfig(
      code: json['code'] as String? ?? 'generaliste',
      name: json['name'] as String? ?? 'Généraliste',
      defaultFlags: (json['defaultFlags'] as Map<String, dynamic>?) ?? {},
      visibleSections: (json['visibleSections'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      suggestedCategories: (json['suggestedCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      roleLabels: (json['roleLabels'] as Map<String, dynamic>?) ?? {},
      documentType: json['documentType'] as String? ?? 'receipt',
      roleScreenAccess: roleScreenAccess,
    );
  }

  static BusinessTypeConfig get fallback => const BusinessTypeConfig(
        code: 'generaliste',
        name: 'Généraliste',
        defaultFlags: {},
        visibleSections: [],
        suggestedCategories: [],
        roleLabels: {},
        documentType: 'receipt',
        roleScreenAccess: {},
      );
}

class BusinessTypeConfigRepository {
  final http.Client _httpClient;

  BusinessTypeConfigRepository({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  String? _token() {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<BusinessTypeConfig> getMyConfig(String tenantId) async {
    final response = await _httpClient.get(
      Uri.parse('${ApiConstants.baseUrl}/business-type/config'),
      headers: ApiConstants.headers(tenantId: tenantId, token: _token()),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return BusinessTypeConfig.fromJson(json);
    }
    // Fallback gracieux — aucune adaptation si config indisponible
    return BusinessTypeConfig.fallback;
  }
}
