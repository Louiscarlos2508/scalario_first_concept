import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/data/models/tenant_module_status.dart';
import 'package:frontend/features/admin/data/models/tenant_summary.dart';
import 'package:frontend/features/admin/data/services/admin_api_service.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:frontend/features/admin/presentation/screens/admin_modules_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _tenants = [
  const TenantSummary(
      id: 't-1',
      name: 'Demo Store',
      status: 'active',
      currency: 'XOF',
      membersCount: 3,
      activeModules: ['catalog']),
  const TenantSummary(
      id: 't-2',
      name: 'Test Store',
      status: 'active',
      currency: 'XOF',
      membersCount: 1,
      activeModules: []),
];

final _modules = [
  const TenantModuleStatus(
      moduleCode: 'catalog',
      name: 'Catalogue',
      type: 'shared',
      status: 'active',
      dependencies: []),
  const TenantModuleStatus(
      moduleCode: 'inventory',
      name: 'Inventaire',
      type: 'shared',
      status: 'inactive',
      dependencies: ['catalog']),
  const TenantModuleStatus(
      moduleCode: 'retail',
      name: 'Point de Vente',
      type: 'vertical',
      status: 'inactive',
      dependencies: ['catalog', 'inventory']),
];

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _wrap({
  List<TenantSummary>? tenants,
  List<TenantModuleStatus>? modules,
  AdminApiService? apiService,
}) {
  return ProviderScope(
    overrides: [
      adminTenantsProvider.overrideWith((_) => Future.value(tenants ?? _tenants)),
      tenantModulesProvider
          .overrideWith((ref, id) => Future.value(modules ?? [])),
      if (apiService != null)
        adminApiServiceProvider.overrideWithValue(apiService),
    ],
    child: const MaterialApp(home: Scaffold(body: AdminModulesScreen())),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AdminModulesScreen', () {
    testWidgets('shows hint when no tenant selected', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byKey(const Key('modules_tenant_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('modules_select_hint')), findsOneWidget);
    });

    testWidgets('selecting tenant shows grouped module tiles', (tester) async {
      await tester.pumpWidget(_wrap(modules: _modules));
      await tester.pump();

      await tester.tap(find.byKey(const Key('modules_tenant_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Store').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('module_tile_catalog')), findsOneWidget);
      expect(find.byKey(const Key('module_tile_inventory')), findsOneWidget);
      expect(find.byKey(const Key('module_tile_retail')), findsOneWidget);
      expect(find.text('Modules partagés'), findsOneWidget);
      expect(find.text('Modules verticaux'), findsOneWidget);
    });

    testWidgets('toggle ON → POST activate called', (tester) async {
      final captured = <http.Request>[];
      final service = AdminApiService(
        client: MockClient((req) async {
          captured.add(req);
          return http.Response('{}', 200);
        }),
      );

      await tester.pumpWidget(_wrap(modules: _modules, apiService: service));
      await tester.pump();

      await tester.tap(find.byKey(const Key('modules_tenant_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Store').last);
      await tester.pumpAndSettle();

      // inventory is inactive → toggle ON
      await tester.tap(find.byKey(const Key('module_toggle_inventory')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(captured, hasLength(1));
      expect(captured.first.url.path, contains('activate'));
      expect(captured.first.url.path, contains('inventory'));
    });

    testWidgets('toggle OFF → confirmation dialog → confirm → POST deactivate',
        (tester) async {
      final captured = <http.Request>[];
      final service = AdminApiService(
        client: MockClient((req) async {
          captured.add(req);
          return http.Response('{}', 200);
        }),
      );

      await tester.pumpWidget(_wrap(modules: _modules, apiService: service));
      await tester.pump();

      await tester.tap(find.byKey(const Key('modules_tenant_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Store').last);
      await tester.pumpAndSettle();

      // catalog is active → toggle OFF
      await tester.tap(find.byKey(const Key('module_toggle_catalog')));
      await tester.pumpAndSettle();

      expect(find.text('Désactiver le module ?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_deactivate')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(captured, hasLength(1));
      expect(captured.first.url.path, contains('deactivate'));
      expect(captured.first.url.path, contains('catalog'));
    });

    testWidgets('activate 422 MISSING_DEPENDENCY shows error snackbar',
        (tester) async {
      final service = AdminApiService(
        client: MockClient((_) async => http.Response(
              jsonEncode(
                  {'error': 'MISSING_DEPENDENCY', 'missing': ['catalog']}),
              422,
            )),
      );

      await tester.pumpWidget(_wrap(modules: _modules, apiService: service));
      await tester.pump();

      await tester.tap(find.byKey(const Key('modules_tenant_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Store').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('module_toggle_inventory')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('snackbar_module_error')), findsOneWidget);
    });

    testWidgets('toggle OFF cancel → deactivate NOT called', (tester) async {
      final captured = <http.Request>[];
      final service = AdminApiService(
        client: MockClient((req) async {
          captured.add(req);
          return http.Response('{}', 200);
        }),
      );

      await tester.pumpWidget(_wrap(modules: _modules, apiService: service));
      await tester.pump();

      await tester.tap(find.byKey(const Key('modules_tenant_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo Store').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('module_toggle_catalog')));
      await tester.pumpAndSettle();

      expect(find.text('Désactiver le module ?'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(captured, isEmpty);
    });
  });
}
