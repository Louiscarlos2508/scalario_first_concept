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
import 'package:frontend/features/retail/pos/presentation/state/cart_state.dart';
import 'package:frontend/features/retail/pos/presentation/state/session_notifier.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/cart_panel.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/reservation_deposit_dialog.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/presentation/providers/business_type_config_provider.dart';
import 'package:frontend/features/shared/catalog/presentation/providers/catalog_providers.dart'
    show lowStockCountProvider;
import 'package:frontend/features/shared/client_orders/domain/models/client_order.dart';
import 'package:frontend/features/shared/client_orders/presentation/providers/client_order_kpis_provider.dart';
import 'package:frontend/features/shared/expenses/data/models/expense.dart';
import 'package:frontend/features/shared/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/shared/freshness/presentation/providers/freshness_provider.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/providers/purchase_orders_providers.dart';
import 'package:frontend/features/shared/reports/data/models/sales_stat.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/reports/presentation/widgets/kpi_card_grid.dart';
import 'package:frontend/features/shared/reservations/data/repositories/reservations_repository.dart';
import 'package:frontend/features/shared/reservations/presentation/providers/reservations_provider.dart';
import 'package:frontend/features/shared/reservations/presentation/screens/reservations_screen.dart';
import 'package:frontend/features/shared/stock_alerts/presentation/providers/stock_alerts_provider.dart';
import 'package:frontend/core/providers/payment_methods_provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:isar/isar.dart';

// ── Stubs ──────────────────────────────────────────────────────────────────

class _StubIsarService extends IsarService {
  @override
  Future<Isar> initDb() => Completer<Isar>().future;
}

class _StubSyncService extends SyncService {
  final _ctrl = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _ctrl.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
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

// ── Fixtures ───────────────────────────────────────────────────────────────

UserProfile _profileWithRole(String role) => UserProfile(
      id: 'user-1',
      email: 'test@example.com',
      memberships: [TenantMembership(tenantId: 'tenant-1', role: role)],
    );

final _mockSession = PosSession()
  ..userId = 'user-1'
  ..tenantId = 'tenant-1'
  ..status = 'OPEN'
  ..openingBalance = 0
  ..openedAt = DateTime.now();

CartState _cartWith10k() {
  final product = Product()
    ..id = 1
    ..remoteId = 'prod-1'
    ..name = 'Test Produit'
    ..price = 10000
    ..stockQuantity = 5
    ..tenantId = 'tenant-1';
  return CartState(items: [CartItem(product: product, quantity: 1)]);
}

final _pendingReservation = <String, dynamic>{
  'id': 'res-uuid-001',
  'customerId': 'cust-0001',
  'customerName': 'Client Test',
  'totalAmount': 10000,
  'depositAmount': 3000,
  'remainingAmount': 7000,
  'status': 'pending',
  'createdAt': '2026-03-25T10:00:00.000Z',
};

// ── Widget builders ─────────────────────────────────────────────────────────

Widget _buildDepositDialog(CartState cartState) {
  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      userProfileProvider.overrideWith(
        (ref) => Future.value(_profileWithRole('commercial')),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: ReservationDepositDialog(cartState: cartState)),
    ),
  );
}

Widget _buildCartPanel() {
  return ProviderScope(
    overrides: [
      isarServiceProvider.overrideWithValue(_StubIsarService()),
      userProfileProvider.overrideWith(
        (ref) => Future.value(_profileWithRole('commercial')),
      ),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      sessionProvider.overrideWith((ref) => _FakeSessionNotifier(_mockSession)),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      enabledPaymentMethodsProvider
          .overrideWith((ref) => Future.value([const PaymentMethod('CASH', 'Espèces')])),
    ],
    child: const MaterialApp(home: Scaffold(body: CartPanel())),
  );
}

Widget _buildReservationsScreen({
  List<Map<String, dynamic>> pending = const [],
}) {
  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      userProfileProvider.overrideWith(
        (ref) => Future.value(_profileWithRole('manager')),
      ),
      reservationsRepositoryProvider.overrideWithValue(
        ReservationsRepository(
          httpClient: MockClient(
            (_) async => http.Response('{"items":[]}', 200),
          ),
        ),
      ),
      reservationsListProvider('pending')
          .overrideWith((ref) => Future.value(pending)),
      reservationsListProvider('completed')
          .overrideWith((ref) => Future.value(<dynamic>[])),
      reservationsListProvider('cancelled')
          .overrideWith((ref) => Future.value(<dynamic>[])),
      unreadNotificationCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: const MaterialApp(home: ReservationsScreen()),
  );
}

Widget _buildKpiCardGrid({int reservationsPending = 0}) {
  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      userProfileProvider.overrideWith(
        (ref) => Future.value(_profileWithRole('owner')),
      ),
      salesStatsProvider.overrideWith(
        (ref) => Future.value([
          SalesStat(
            day: DateTime(2026, 3, 25),
            revenue: 100000,
            orderCount: 5,
          ),
        ]),
      ),
      expensesProvider.overrideWith((ref) => Future.value(<Expense>[])),
      purchaseOrderStatsProvider.overrideWith(
        (ref) => Future.value(<String, int>{'total': 0}),
      ),
      stockAlertCountProvider.overrideWith((ref) async => 0),
      urgentBatchCountProvider.overrideWith((ref) async => 0),
      reservationsKpiProvider.overrideWith(
        (ref) => Future.value({
          'pendingCount': reservationsPending,
          'totalDepositAmount': 0,
        }),
      ),
      clientOrderKpisProvider
          .overrideWith((ref) => Future.value(ClientOrderKpis.zero)),
      lowStockCountProvider.overrideWith((ref) async => 0),
      businessTypeConfigProvider
          .overrideWith((ref) => Future.value(BusinessTypeConfig.fallback)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: KpiCardGrid()),
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('ReservationDepositDialog', () {
    testWidgets('champs Client et Acompte présents dans le dialog',
        (tester) async {
      await tester.pumpWidget(_buildDepositDialog(_cartWith10k()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Client'), findsWidgets);
      expect(find.textContaining('Acompte'), findsWidgets);
      expect(find.text('Confirmer'), findsOneWidget);
    });

    testWidgets('acompte 5% → erreur visible et bouton désactivé',
        (tester) async {
      await tester.pumpWidget(_buildDepositDialog(_cartWith10k()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // La dernière TextField est le champ acompte
      await tester.enterText(find.byType(TextField).last, '500');
      await tester.pump();

      // Error message format: "Acompte entre X (10%) et Y (50%)"
      expect(find.textContaining('Acompte entre'), findsOneWidget);

      final btn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Confirmer'),
      );
      expect(btn.onPressed, isNull,
          reason:
              'Bouton désactivé : acompte invalide et aucun client sélectionné');
    });

    testWidgets('acompte 30% → aucune erreur et solde restant affiché',
        (tester) async {
      await tester.pumpWidget(_buildDepositDialog(_cartWith10k()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).last, '3000');
      await tester.pump();

      expect(find.textContaining('Acompte entre'), findsNothing);
      expect(find.textContaining('Solde'), findsOneWidget);
    });
  });

  group('CartPanel — bouton Réservation', () {
    testWidgets('bouton RÉSA présent dans le widget tree', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildCartPanel());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('RÉSA'), findsOneWidget);
    });
  });

  group('ReservationsScreen', () {
    testWidgets('TabBar contient les 3 onglets', (tester) async {
      await tester.pumpWidget(_buildReservationsScreen());
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.text('En cours'), findsOneWidget);
      expect(find.text('Complétées'), findsOneWidget);
      expect(find.text('Annulées'), findsOneWidget);
    });

    testWidgets(
      'onglet "En cours" affiche boutons Compléter et Annuler pour chaque réservation',
      (tester) async {
        await tester.pumpWidget(
          _buildReservationsScreen(pending: [_pendingReservation]),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(find.text('Compléter'), findsOneWidget);
        expect(find.text('Annuler'), findsOneWidget);
      },
    );
  });

  group('KpiCardGrid — alerte réservations', () {
    testWidgets(
      'alerte "réservation(s) en cours" visible pour owner avec 3 pending',
      (tester) async {
        await tester.pumpWidget(_buildKpiCardGrid(reservationsPending: 3));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('réservation'), findsOneWidget);
      },
    );

    testWidgets(
      'aucune alerte réservation si pendingCount = 0',
      (tester) async {
        await tester.pumpWidget(_buildKpiCardGrid(reservationsPending: 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.textContaining('réservation'), findsNothing);
      },
    );
  });
}
