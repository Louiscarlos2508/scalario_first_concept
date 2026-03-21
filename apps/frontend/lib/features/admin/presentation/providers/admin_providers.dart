import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;
import '../../data/models/business_type_summary.dart';
import '../../data/models/monitoring_health.dart';
import '../../data/models/tenant_module_status.dart';
import '../../data/models/tenant_summary.dart';
import '../../data/models/tenant_user.dart';
import '../../data/services/admin_api_service.dart';

String _token() =>
    Supabase.instance.client.auth.currentSession?.accessToken ?? '';

final adminApiServiceProvider = Provider<AdminApiService>(
  (ref) => AdminApiService(),
);

final adminTenantsProvider = FutureProvider<List<TenantSummary>>((ref) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref.read(adminApiServiceProvider).fetchTenants(token: token);
});

final tenantModulesProvider =
    FutureProvider.family<List<TenantModuleStatus>, String>(
        (ref, tenantId) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref
      .read(adminApiServiceProvider)
      .getTenantModules(tenantId, token: token);
});

final tenantUsersProvider =
    FutureProvider.family<List<TenantUser>, String>((ref, tenantId) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref
      .read(adminApiServiceProvider)
      .getTenantUsers(tenantId, token: token);
});

final adminMonitoringProvider =
    FutureProvider<MonitoringHealth>((ref) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref
      .read(adminApiServiceProvider)
      .getMonitoringHealth(token: token);
});

final planDefinitionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref.read(adminApiServiceProvider).fetchPlans(token: token);
});

final tenantBillingProvider =
    FutureProvider.family<Map<String, dynamic>, String>(
        (ref, tenantId) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref
      .read(adminApiServiceProvider)
      .getTenantBilling(tenantId, token: token);
});

final businessTypesProvider =
    FutureProvider<List<BusinessTypeSummary>>((ref) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref.read(adminApiServiceProvider).fetchBusinessTypes(token: token);
});

final billingSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref.read(adminApiServiceProvider).getBillingSummary(token: token);
});

final allBillingEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>(
        (ref, filters) async {
  final token = _token();
  if (token.isEmpty) throw Exception('Not authenticated');
  return ref.read(adminApiServiceProvider).listAllBillingEvents(
        tenantId: filters['tenantId'],
        type: filters['type'],
        status: filters['status'],
        token: token,
      );
});
