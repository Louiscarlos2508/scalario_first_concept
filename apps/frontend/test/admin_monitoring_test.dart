import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/data/models/monitoring_health.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:frontend/features/admin/presentation/screens/admin_monitoring_screen.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _tenantOk = TenantHealthStatus(
  id: 't-1',
  name: 'Boutique Sano',
  status: 'active',
  createdAt: DateTime(2026, 1, 1),
  membersCount: 3,
  lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)),
  failedMutationsCount: 0,
);

final _tenantAlert = TenantHealthStatus(
  id: 't-2',
  name: 'Boutique Koné',
  status: 'active',
  createdAt: DateTime(2026, 1, 15),
  membersCount: 5,
  lastActivityAt: null,
  failedMutationsCount: 15,
);

MonitoringHealth _health({
  int activeTenants = 2,
  int totalUsers = 5,
  List<TenantHealthStatus>? tenants,
}) =>
    MonitoringHealth(
      activeTenants: activeTenants,
      totalUsers: totalUsers,
      tenants: tenants ?? [_tenantOk],
    );

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _wrap(MonitoringHealth health) {
  return ProviderScope(
    overrides: [
      adminMonitoringProvider.overrideWith((_) => Future.value(health)),
    ],
    child: const MaterialApp(home: AdminMonitoringScreen()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AdminMonitoringScreen', () {
    testWidgets('KPI cards show activeTenants and totalUsers', (tester) async {
      await tester.pumpWidget(_wrap(_health(activeTenants: 2, totalUsers: 5)));
      await tester.pump();

      expect(find.text('Tenants actifs'), findsOneWidget);
      expect(find.text('Utilisateurs totaux'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('tenant with failedMutationsCount = 0 shows check_circle icon',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_health(tenants: [_tenantOk])));
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsNothing);
    });

    testWidgets(
        'tenant with failedMutationsCount > 10 shows warning icon and badge',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_health(tenants: [_tenantAlert])));
      await tester.pump();

      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('tap on alert tenant shows AlertDialog', (tester) async {
      await tester.pumpWidget(
          _wrap(_health(tenants: [_tenantAlert])));
      await tester.pump();

      await tester.tap(find.text('Boutique Koné'));
      await tester.pumpAndSettle();

      expect(find.text('Alertes sync — Boutique Koné'), findsOneWidget);
      expect(find.textContaining('15 mutations'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);
    });

    testWidgets('pull to refresh triggers provider refresh', (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminMonitoringProvider.overrideWith((_) {
              callCount++;
              return Future.value(_health());
            }),
          ],
          child: const MaterialApp(home: AdminMonitoringScreen()),
        ),
      );
      await tester.pump();

      // Initial load
      expect(callCount, greaterThanOrEqualTo(1));

      // Pull to refresh — drag from center downward
      await tester.drag(
          find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(callCount, greaterThan(1));
    });
  });
}
