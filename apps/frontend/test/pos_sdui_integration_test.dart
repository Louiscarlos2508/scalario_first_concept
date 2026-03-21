import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_renderer.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/state/session_notifier.dart';
import 'package:isar/isar.dart';

// ── Test doubles ─────────────────────────────────────────────────────────────

class _StubIsarService extends IsarService {
  @override
  Future<Isar> initDb() => Completer<Isar>().future;
}

class _FakeSessionNotifier extends SessionNotifier {
  final PosSession _seed;
  _FakeSessionNotifier(this._seed)
      : super(
          SessionRepository(_StubIsarService()),
          OrderRepository(_StubIsarService()),
          userId: 'user-1',
        ) {
    state = AsyncValue.data(_seed);
  }

  @override
  Future<void> checkActiveSession() async {}
}

class _StubSyncService extends SyncService {
  final _controller = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _controller.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
}

// ── Shared fixtures ───────────────────────────────────────────────────────────

final _mockProducts = [
  Product()
    ..id = 1
    ..name = 'Cola'
    ..price = 100
    ..stockQuantity = 10
    ..remoteId = 'p-1',
];

final _mockProfile = UserProfile(
  id: 'u-1',
  email: 'cashier@test.com',
  memberships: [TenantMembership(tenantId: 'tenant-1', role: 'cashier')],
);

final _mockSession = PosSession()
  ..userId = 'u-1'
  ..tenantId = 'tenant-1'
  ..status = 'OPEN'
  ..openingBalance = 0
  ..openedAt = DateTime.now();

/// Build the POS screen with all providers stubbed.
/// [layoutResult] overrides the sduiLayoutProvider response.
Widget _buildPosScreen({Future<SduiLayout>? layoutResult}) {
  return ProviderScope(
    overrides: [
      isarServiceProvider.overrideWithValue(_StubIsarService()),
      productListProvider.overrideWith((ref) => Future.value(_mockProducts)),
      categoriesProvider.overrideWith((ref) => Future.value([])),
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      sessionProvider.overrideWith((ref) => _FakeSessionNotifier(_mockSession)),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      cartProvider.overrideWith((ref) => CartNotifier()),
      sduiLayoutProvider('pos').overrideWith(
        (ref) =>
            layoutResult ?? Future.value(SduiLayout.retailPosDefault()),
      ),
    ],
    child: const MaterialApp(home: PosScreen()),
  );
}

/// Wrap SduiRenderer in a MediaQuery at [width]×[height].
/// MediaQuery is placed OUTSIDE MaterialApp so LayoutBuilder reads the right
/// constraints (matching the pattern in sdui_renderer_test.dart).
/// Wraps SduiRenderer in a SizedBox(width) so LayoutBuilder receives
/// accurate constraints regardless of the test surface size.
Widget _buildRendererAt(double width, SduiLayout layout) {
  return ProviderScope(
    overrides: [cartProvider.overrideWith((ref) => CartNotifier())],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: SduiRenderer(layout: layout)),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SduiWidgetRegistry.reset();
    SduiWidgetRegistry.register('product_grid', (_) => const Text('ProductGrid'));
    SduiWidgetRegistry.register('cart_panel', (_) => const Text('CartPanel'));
  });

  tearDown(() => SduiWidgetRegistry.reset());

  // ── AC4: Tablet — horizontal_split ────────────────────────────────────────
  // Tests SduiRenderer directly at 800dp to verify horizontal_split layout.

  group('Tablet layout (AC4) — horizontal_split', () {
    testWidgets('800dp wide renders product_grid and cart_panel side-by-side',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(800, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      expect(find.text('ProductGrid'), findsOneWidget);
      expect(find.text('CartPanel'), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  // ── AC5: Phone — stacked_with_fab_cart ────────────────────────────────────
  // Tests SduiRenderer directly at 400dp to verify compact layout + FAB.

  group('Phone layout (AC5) — stacked_with_fab_cart', () {
    testWidgets('400dp wide renders product_grid with FAB cart badge',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(400, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      expect(find.text('ProductGrid'), findsOneWidget);
      expect(find.text('CartPanel'), findsNothing); // inline cart hidden in compact
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB badge tooltip shows 0 items for empty cart',
        (tester) async {
      await tester.pumpWidget(
        _buildRendererAt(400, SduiLayout.retailPosDefault()),
      );
      await tester.pump();

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.tooltip, contains('0'));
    });
  });

  // ── AC3: Offline fallback ─────────────────────────────────────────────────

  group('Offline fallback (AC3)', () {
    testWidgets(
        'loading state uses retailPosDefault — no blank screen while fetching',
        (tester) async {
      // Never-completing future → provider stays in loading state
      final never = Completer<SduiLayout>().future;
      await tester.pumpWidget(_buildPosScreen(layoutResult: never));
      await tester.pump();

      // PosScreen loading: branch uses SduiLayout.retailPosDefault()
      expect(find.text('ProductGrid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
