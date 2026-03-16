import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/dashboard_shell.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

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

/// Build DashboardShell constrained to [width] inside a Scaffold body.
/// SizedBox(width) ensures LayoutBuilder inside DashboardShell receives
/// accurate maxWidth constraints regardless of the test surface size.
Widget _buildShellAt(double width) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-nav'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: DashboardShell(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
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
    // AC1 + AC3: phone breakpoint → BottomNavigationBar
    testWidgets(
        'At 400dp: BottomNavigationBar present, NavigationRail absent',
        (tester) async {
      await tester.pumpWidget(_buildShellAt(400));
      await tester.pump();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    // AC1 + AC4: tablet breakpoint → NavigationRail
    testWidgets(
        'At 800dp: NavigationRail present, BottomNavigationBar absent',
        (tester) async {
      await tester.pumpWidget(_buildShellAt(800));
      await tester.pump(); // resolve FutureProvider
      await tester.pump(const Duration(milliseconds: 50)); // settle layout

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
