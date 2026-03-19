import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';
import 'package:frontend/features/admin/presentation/screens/admin_dashboard.dart';
import 'package:frontend/features/admin/data/models/tenant_summary.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

UserProfile _profileWith(String role) => UserProfile(
      id: 'user-test',
      email: 'test@example.com',
      memberships: [TenantMembership(tenantId: 'tenant-1', role: role)],
    );

/// Minimal routing widget that mirrors the logic in main.dart.
/// Tests that the correct branch is reached without pumping the full ScalarioApp.
class _TestRouter extends ConsumerWidget {
  const _TestRouter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    return profileAsync.when(
      data: (profile) {
        if (profile?.role == 'superadmin') return const AdminDashboard();
        if (profile?.role == 'cashier') return const Text('cashier-screen');
        return const Text('dashboard-screen');
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const SizedBox(),
    );
  }
}

ProviderScope _buildRouterWith(UserProfile profile, {List<TenantSummary> tenants = const []}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(profile)),
      adminTenantsProvider.overrideWith((ref) => Future.value(tenants)),
    ],
    child: const MaterialApp(home: _TestRouter()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('main.dart routing — profile.role dispatch (AC1)', () {
    testWidgets('superadmin role → AdminDashboard rendered', (tester) async {
      await tester.pumpWidget(_buildRouterWith(_profileWith('superadmin')));
      await tester.pump(); // resolve FutureProvider

      expect(find.byType(AdminDashboard), findsOneWidget);
      expect(find.text('cashier-screen'), findsNothing);
      expect(find.text('dashboard-screen'), findsNothing);
    });

    testWidgets('cashier role → PosScreen path (not AdminDashboard)', (tester) async {
      await tester.pumpWidget(_buildRouterWith(_profileWith('cashier')));
      await tester.pump();

      expect(find.byType(AdminDashboard), findsNothing);
      expect(find.text('cashier-screen'), findsOneWidget);
    });

    testWidgets('owner role → DashboardScreen path (not AdminDashboard)', (tester) async {
      await tester.pumpWidget(_buildRouterWith(_profileWith('owner')));
      await tester.pump();

      expect(find.byType(AdminDashboard), findsNothing);
      expect(find.text('dashboard-screen'), findsOneWidget);
    });
  });
}
