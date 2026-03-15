import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/pos/data/models/pos_session.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/pos/presentation/state/session_notifier.dart';
import 'package:isar/isar.dart';

// Stub IsarService whose initDb never completes — repositories are created
// but never actually access the database.
class _StubIsarService extends IsarService {
  @override
  Future<Isar> initDb() => Completer<Isar>().future;
}

// Fake SessionNotifier that pre-seeds state with a given session and
// skips the real checkActiveSession (which would touch Isar).
class _FakeSessionNotifier extends SessionNotifier {
  final PosSession _seed;

  _FakeSessionNotifier(this._seed)
      : super(
          SessionRepository(_StubIsarService()),
          OrderRepository(_StubIsarService()),
        ) {
    state = AsyncValue.data(_seed);
  }

  @override
  Future<void> checkActiveSession() async {} // no-op — avoids Isar access
}

// Stub SyncService with a stream that never emits — prevents pumpAndSettle timeout.
class _StubSyncService extends SyncService {
  final _controller = StreamController<SyncUiStatus>.broadcast();

  @override
  Stream<SyncUiStatus> get statusStream => _controller.stream;

  @override
  Future<void> startSync(String? tenantId) async {} // no-op
}

// Mock Data
final mockProducts = [
  Product()
    ..id = 1
    ..name = 'Test Cola'
    ..price = 100
    ..stockQuantity = 10
    ..remoteId = 'test-1',
  Product()
    ..id = 2
    ..name = 'Test Burger'
    ..price = 200
    ..stockQuantity = 5
    ..remoteId = 'test-2',
];

final _mockProfile = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  memberships: [TenantMembership(tenantId: 'tenant-1', role: 'cashier')],
);

final _mockSession = PosSession()
  ..userId = 'user-1'
  ..tenantId = 'tenant-1'
  ..status = 'OPEN'
  ..openingBalance = 0
  ..openedAt = DateTime.now();

void main() {
  testWidgets('POS Screen renders products and adds to cart', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarServiceProvider.overrideWithValue(_StubIsarService()),
          productListProvider.overrideWith((ref) => Future.value(mockProducts)),
          categoriesProvider.overrideWith((ref) => Future.value([])),
          userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
          activeTenantProvider.overrideWith((ref) => 'tenant-1'),
          sessionProvider.overrideWith((ref) => _FakeSessionNotifier(_mockSession)),
          syncServiceProvider.overrideWithValue(_StubSyncService()),
        ],
        child: const MaterialApp(
          home: PosScreen(),
        ),
      ),
    );

    // Initial load might be async
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100)); // Wait for future

    // Verify Product Grid
    expect(find.text('Test Cola'), findsOneWidget);
    expect(find.text('\$100.00'), findsOneWidget);
    expect(find.text('Test Burger'), findsOneWidget);

    // Verify Cart is empty initially
    expect(find.text('Total:'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);

    // Tap to add "Test Cola" - Specific to Grid Card to avoid ambiguity with Cart List
    await tester.tap(find.widgetWithText(Card, 'Test Cola'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Cart Update
    // The grid also shows $100.00. The cart item subtitle shows "1 x $100.00" (updated).

    // Check for Cart Item in list
    expect(find.widgetWithText(ListTile, 'Test Cola'), findsOneWidget);

    // Tap to add another "Test Cola"
    await tester.tap(find.widgetWithText(Card, 'Test Cola'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Quantity update
    // Subtitle should be "2 x $100.0"
    expect(find.textContaining('2 x'), findsOneWidget);

    // Verify Total is $200
    // "Test Burger" in grid ($200.00).
    // Cola Item Trailing ($200.00).
    // Cart Grand Total ($200.00).
    expect(find.text('\$200.00'), findsNWidgets(3));
  });
}
