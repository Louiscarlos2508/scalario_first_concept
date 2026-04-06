import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/backoffice/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';

// ── Test doubles ─────────────────────────────────────────────────────────────

class _StubSyncService extends SyncService {
  final _controller = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _controller.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
}

// ── Fixtures ─────────────────────────────────────────────────────────────────

final _mockProfile = UserProfile(
  id: 'u-nav-1',
  email: 'owner@nav.test',
  memberships: [TenantMembership(tenantId: 'tenant-nav', role: 'owner')],
);

/// Sample nav items that include "Dépenses".
final _items = [
  const NavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Tableau de bord'),
  const NavItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Dépenses',
      moduleCode: 'expenses'),
  const NavItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Inventaire'),
];

/// Build DashboardShell constrained to [width] inside a Scaffold body.
Widget _buildShellAt(double width) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-nav'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      unreadNotificationCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: DashboardShell(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            items: _items,
            child: const SizedBox(),
          ),
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DashboardShell — responsive navigation (AC1, AC3, AC4)', () {
    // AC1 + AC3: phone breakpoint → NavigationBar (Material 3)
    testWidgets(
        'At 400dp: NavigationBar present, no sidebar',
        (tester) async {
      await tester.pumpWidget(_buildShellAt(400));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(find.byType(NavigationBar), findsOneWidget);
      // No sidebar (tablet layout uses a 220dp-wide dark container)
      expect(find.text('Déconnexion'), findsNothing);
    });

    // AC1 + AC4: tablet breakpoint → custom dark sidebar
    testWidgets(
        'At 800dp: sidebar present, NavigationBar absent',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildShellAt(800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sidebar shows sign-out button
      expect(find.text('Déconnexion'), findsOneWidget);
      // No bottom NavigationBar
      expect(find.byType(NavigationBar), findsNothing);
    });

    // Story 17-3: "Dépenses" nav destination present in sidebar
    testWidgets(
        'At 800dp: sidebar includes "Dépenses" destination',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildShellAt(800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dépenses'), findsOneWidget);
    });
  });
}
