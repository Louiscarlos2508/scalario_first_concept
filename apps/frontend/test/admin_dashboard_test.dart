import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:frontend/features/admin/presentation/screens/admin_dashboard.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildDashboardAt(double width) {
  return ProviderScope(
    overrides: [
      adminTenantsProvider.overrideWith((ref) => Future.value(const [])),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: const AdminDashboard(),
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('AdminDashboard — responsive navigation (AC2)', () {
    testWidgets('width 600 → NavigationBar (bottom nav) rendered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildDashboardAt(600));
      await tester.pump();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('width 1200 → NavigationRail rendered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildDashboardAt(1200));
      await tester.pump();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('3 destinations are present: Tenants, Modules, Monitoring', (tester) async {
      await tester.pumpWidget(_buildDashboardAt(600));
      await tester.pump();

      expect(find.text('Tenants'), findsAtLeastNWidgets(1));
      expect(find.text('Modules'), findsAtLeastNWidgets(1));
      expect(find.text('Monitoring'), findsAtLeastNWidgets(1));
    });
  });
}
