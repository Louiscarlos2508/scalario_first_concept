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
import 'package:frontend/features/retail/pos/presentation/state/cart_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/state/session_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_panel.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/discount_dialog.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:isar/isar.dart';

// ─── Stubs & fakes ─────────────────────────────────────────────────────────

class _StubIsarService extends IsarService {
  @override
  Future<Isar> initDb() => Completer<Isar>().future;
}

class _FakeSessionNotifier extends SessionNotifier {
  _FakeSessionNotifier(PosSession seed)
      : super(
          SessionRepository(_StubIsarService()),
          OrderRepository(_StubIsarService()),
          userId: 'user-1',
          tenantId: 'tenant-1',
          tokenGetter: () => null,
        ) {
    state = AsyncValue.data(seed);
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

/// Pre-seeds the cart with a given [CartState] without touching Isar.
class _FakeCartNotifier extends CartNotifier {
  _FakeCartNotifier(CartState seed) {
    state = seed;
  }
}

// ─── Fixtures ───────────────────────────────────────────────────────────────

final _mockProduct = Product()
  ..id = 1
  ..name = 'Test Cola'
  ..price = 500
  ..stockQuantity = 10
  ..remoteId = 'test-1';

final _cartWithItem = CartState(
  items: [CartItem(product: _mockProduct, quantity: 1)],
);

final _mockSession = PosSession()
  ..userId = 'user-1'
  ..tenantId = 'tenant-1'
  ..status = 'OPEN'
  ..openingBalance = 0
  ..openedAt = DateTime.now();

UserProfile _profileFor(String role) => UserProfile(
      id: 'user-1',
      email: 'test@example.com',
      memberships: [TenantMembership(tenantId: 'tenant-1', role: role)],
    );

// ─── Widget builder ─────────────────────────────────────────────────────────

Widget _buildCartPanel({required String role, CartState? initialCart}) {
  return ProviderScope(
    overrides: [
      isarServiceProvider.overrideWithValue(_StubIsarService()),
      cartProvider.overrideWith(
          (ref) => _FakeCartNotifier(initialCart ?? _cartWithItem)),
      userProfileProvider
          .overrideWith((ref) => Future.value(_profileFor(role))),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      sessionProvider
          .overrideWith((ref) => _FakeSessionNotifier(_mockSession)),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      enabledPaymentMethodsProvider
          .overrideWith((ref) => Future.value([const PaymentMethod('CASH', 'Espèces')])),
    ],
    child: const MaterialApp(home: Scaffold(body: CartPanel())),
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('CartPanel RBAC — clear cart', () {
    for (final role in ['cashier', 'commercial', 'manager', 'owner']) {
      testWidgets('$role can clear the cart', (tester) async {
        await tester.pumpWidget(_buildCartPanel(role: role));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(find.text('Test Cola'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(find.text('Test Cola'), findsNothing);
      });
    }

    testWidgets('clear cart button is disabled when cart is empty',
        (tester) async {
      await tester.pumpWidget(
          _buildCartPanel(role: 'cashier', initialCart: CartState()));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      final btn = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.delete_outline));
      expect(btn.onPressed, isNull);
    });
  });

  group('CartPanel RBAC — remove item', () {
    // Product is unitType == 'piece' (default), so the _QtyBtn minus is shown.
    // Tapping the minus button with qty=1 removes the item.
    for (final role in ['cashier', 'commercial', 'manager', 'owner']) {
      testWidgets('$role can remove an item via qty minus', (tester) async {
        await tester.pumpWidget(_buildCartPanel(role: role));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(find.text('Test Cola'), findsOneWidget);

        // The minus _QtyBtn uses Icons.remove
        await tester.tap(find.byIcon(Icons.remove).first);
        await tester.pumpAndSettle();

        expect(find.text('Test Cola'), findsNothing);
      });
    }
  });

  group('CartPanel RBAC — apply discount', () {
    // The discount icon (Icons.edit_note) is only rendered when isManager is
    // true (role == manager or owner). For cashier/commercial it's absent.

    testWidgets('cashier: no discount icon shown', (tester) async {
      await tester.pumpWidget(_buildCartPanel(role: 'cashier'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.edit_note), findsNothing);
      expect(find.byType(DiscountDialog), findsNothing);
    });

    testWidgets('commercial: no discount icon shown', (tester) async {
      await tester.pumpWidget(_buildCartPanel(role: 'commercial'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.edit_note), findsNothing);
      expect(find.byType(DiscountDialog), findsNothing);
    });

    testWidgets('manager: discount icon opens DiscountDialog', (tester) async {
      await tester.pumpWidget(_buildCartPanel(role: 'manager'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      expect(find.byType(DiscountDialog), findsOneWidget);
    });

    testWidgets('owner: discount icon opens DiscountDialog', (tester) async {
      await tester.pumpWidget(_buildCartPanel(role: 'owner'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.edit_note), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.pumpAndSettle();

      expect(find.byType(DiscountDialog), findsOneWidget);
    });
  });

  group('CartPanel RBAC — price override (long press)', () {
    testWidgets('cashier: long press does not open price override',
        (tester) async {
      await tester.pumpWidget(_buildCartPanel(role: 'cashier'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.longPress(find.text('Test Cola'));
      await tester.pumpAndSettle();

      expect(find.text('Changer le niveau de prix'), findsNothing);
    });

    testWidgets('manager: long press triggers price override lookup',
        (tester) async {
      await tester.pumpWidget(_buildCartPanel(role: 'manager'));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      await tester.longPress(find.text('Test Cola'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
    });
  });
}
