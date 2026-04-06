import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/retail/pos/presentation/screens/pos_screen.dart';
import 'package:frontend/features/retail/pos/presentation/state/session_notifier.dart';
import 'package:isar/isar.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';
import 'package:frontend/core/sdui/sdui_providers.dart';
import 'package:frontend/core/sdui/sdui_widget_registry.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/product_grid.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_panel.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';

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
          tenantId: 'tenant-1',
          tokenGetter: () => null,
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SduiWidgetRegistry.reset();
    SduiWidgetRegistry.register('product_grid', (_) => const ProductGrid());
    SduiWidgetRegistry.register('cart_panel', (_) => const CartPanel());
  });

  tearDown(() => SduiWidgetRegistry.reset());

  testWidgets('POS Screen renders products and adds to cart', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          sduiLayoutProvider('pos').overrideWith(
            (ref) => Future.value(SduiLayout.retailPosDefault()),
          ),
          enabledPaymentMethodsProvider
              .overrideWith((ref) => Future.value([const PaymentMethod('CASH', 'Espèces')])),
          businessTypeConfigProvider
              .overrideWith((ref) => Future.value(BusinessTypeConfig.fallback)),
        ],
        child: const MaterialApp(
          home: PosScreen(),
        ),
      ),
    );

    // Multiple pumps needed: SessionGuard resolves profile/session,
    // then SessionLockWrapper loads SharedPreferences async.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Product Grid
    expect(find.text('Test Cola'), findsOneWidget);
    expect(find.text('Test Burger'), findsOneWidget);

    // Verify Cart is empty initially — Total label
    expect(find.text('Total'), findsOneWidget);
    expect(find.textContaining('FCFA'), findsWidgets);

    // Tap to add "Test Cola" — product tiles use GestureDetector, find by text
    await tester.tap(find.text('Test Cola'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify product name appears in cart area (2 instances: grid + cart)
    expect(find.text('Test Cola'), findsNWidgets(2));

    // Tap to add another "Test Cola"
    await tester.tap(find.text('Test Cola').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify quantity is now 2
    expect(find.text('2'), findsWidgets);
  });
}
