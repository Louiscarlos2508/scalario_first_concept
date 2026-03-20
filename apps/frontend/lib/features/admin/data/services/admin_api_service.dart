import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/constants/api_constants.dart';
import '../models/create_tenant_dto.dart';
import '../models/monitoring_health.dart';
import '../models/tenant_module_status.dart';
import '../models/tenant_summary.dart';
import '../models/tenant_user.dart';

/// Structured error from the admin API (HTTP 422).
class AdminApiException implements Exception {
  final String code;
  final List<String> detail;

  const AdminApiException({required this.code, this.detail = const []});

  @override
  String toString() => 'AdminApiException: $code (${detail.join(', ')})';
}

class AdminApiService {
  final http.Client _client;

  AdminApiService({http.Client? client}) : _client = client ?? http.Client();

  // ── Tenants ──────────────────────────────────────────────────────────────

  Future<List<TenantSummary>> fetchTenants({required String token}) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((e) => TenantSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch tenants: HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createTenant(
    CreateTenantDto dto, {
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants'),
      headers: ApiConstants.headers(token: token),
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 422) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AdminApiException(code: body['error'] as String? ?? 'UNKNOWN');
    }
    throw Exception('Failed to create tenant: HTTP ${response.statusCode}');
  }

  // ── Modules ───────────────────────────────────────────────────────────────

  Future<List<TenantModuleStatus>> getTenantModules(
    String tenantId, {
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/modules'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((e) => TenantModuleStatus.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        'Failed to fetch tenant modules: HTTP ${response.statusCode}');
  }

  Future<void> activateModule(
    String tenantId,
    String moduleCode, {
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/admin/tenants/$tenantId/modules/$moduleCode/activate'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 200) return;
    if (response.statusCode == 422) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AdminApiException(
        code: body['error'] as String? ?? 'UNKNOWN',
        detail: List<String>.from(body['missing'] as List? ?? []),
      );
    }
    throw Exception('Failed to activate module: HTTP ${response.statusCode}');
  }

  Future<void> deactivateModule(
    String tenantId,
    String moduleCode, {
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse(
          '${ApiConstants.baseUrl}/admin/tenants/$tenantId/modules/$moduleCode/deactivate'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 200) return;
    if (response.statusCode == 422) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AdminApiException(
        code: body['error'] as String? ?? 'UNKNOWN',
        detail: List<String>.from(body['dependents'] as List? ?? []),
      );
    }
    throw Exception(
        'Failed to deactivate module: HTTP ${response.statusCode}');
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<List<TenantUser>> getTenantUsers(
    String tenantId, {
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/users'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list
          .map((e) => TenantUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        'Failed to fetch tenant users: HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createTenantUser(
    String tenantId, {
    required String email,
    required String password,
    required String role,
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/users'),
      headers: ApiConstants.headers(token: token),
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 422) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AdminApiException(code: body['error'] as String? ?? 'UNKNOWN');
    }
    throw Exception('Failed to create user: HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> updateUserRole(
    String tenantId,
    String userId,
    String role, {
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse(
          '${ApiConstants.baseUrl}/admin/tenants/$tenantId/users/$userId'),
      headers: ApiConstants.headers(token: token),
      body: jsonEncode({'role': role}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update user role: HTTP ${response.statusCode}');
  }

  Future<void> removeUser(
    String tenantId,
    String userId, {
    required String token,
  }) async {
    final response = await _client.delete(
      Uri.parse(
          '${ApiConstants.baseUrl}/admin/tenants/$tenantId/users/$userId'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 204) return;
    if (response.statusCode == 422) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AdminApiException(code: body['error'] as String? ?? 'UNKNOWN');
    }
    throw Exception('Failed to remove user: HTTP ${response.statusCode}');
  }

  // ── Billing ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchPlans({required String token}) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/plans'),
      headers: ApiConstants.headers(token: token),
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch plans: HTTP ${response.statusCode}');
  }

  Future<void> assignPlan(
    String tenantId,
    String planCode, {
    bool confirmDowngrade = false,
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/plan'),
      headers: ApiConstants.headers(token: token),
      body: jsonEncode({'planCode': planCode, 'confirmDowngrade': confirmDowngrade}),
    );
    if (response.statusCode == 200) return;
    throw Exception('Failed to assign plan: HTTP ${response.statusCode} — ${response.body}');
  }

  Future<Map<String, dynamic>> getTenantBilling(
    String tenantId, {
    required String token,
  }) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/billing'),
      headers: ApiConstants.headers(token: token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch billing: HTTP ${response.statusCode}');
  }

  Future<void> updateTenantBilling(
    String tenantId,
    Map<String, dynamic> payload, {
    required String token,
  }) async {
    final response = await _client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/billing'),
      headers: ApiConstants.headers(token: token),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) return;
    throw Exception('Failed to update billing: HTTP ${response.statusCode}');
  }

  Future<Map<String, dynamic>> recordBillingEvent(
    String tenantId,
    Map<String, dynamic> payload, {
    required String token,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}/admin/tenants/$tenantId/billing/events'),
      headers: ApiConstants.headers(token: token),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to record billing event: HTTP ${response.statusCode}');
  }

  // ── Monitoring ────────────────────────────────────────────────────────────

  Future<MonitoringHealth> getMonitoringHealth({required String token}) async {
    final response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/monitoring/health'),
      headers: ApiConstants.headers(token: token),
    );

    if (response.statusCode == 200) {
      return MonitoringHealth.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception(
        'Failed to load monitoring health: HTTP ${response.statusCode}');
  }
}
