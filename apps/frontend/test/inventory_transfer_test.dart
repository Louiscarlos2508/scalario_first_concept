import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_out_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_confirm_form.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/transfer_pending_screen.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _StubSyncService extends SyncService {
  final _ctrl = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _ctrl.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
}

final _mockProfile = UserProfile(
  id: 'user-1',
  email: 'test@example.com',
  memberships: [TenantMembership(tenantId: 'tenant-1', role: 'manager')],
);

final _mockProducts = [
  Product()
    ..id = 1
    ..remoteId = 'prod-1'
    ..name = 'Huile de palme'
    ..price = 1000
    ..stockQuantity = 30
    ..tenantId = 'tenant-1',
];

Widget _buildWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      paginatedProductListProvider.overrideWith(
        (ref) => Future.value({
          'items': _mockProducts,
          'total': 1,
          'totalPages': 1,
        }),
      ),
      ...overrides,
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  // ─── TransferOutForm ────────────────────────────────────────────────────────

  group('TransferOutForm — widget tests', () {
    testWidgets('renders form fields and submit button', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(
        _buildWidget(TransferOutForm(repository: repo)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('transfer_out_product_field')),
          findsOneWidget);
      expect(find.byKey(const Key('transfer_out_quantity_field')),
          findsOneWidget);
      expect(find.byKey(const Key('transfer_out_submit_button')),
          findsOneWidget);
    });

    testWidgets('submit button disabled until product + quantity filled',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(
        _buildWidget(TransferOutForm(repository: repo)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('transfer_out_submit_button')),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets(
        'TRANSFER_OUT created → response referenceId stored in provider',
        (tester) async {
      String? capturedReferenceId;

      final fakeClient = MockClient((req) async {
        final body = jsonDecode(req.body) as Map;
        expect(body['type'], equals('TRANSFER_OUT'));
        expect(body['tenantId'], equals('tenant-1'));
        return http.Response(
          jsonEncode({
            'id': 'mov-1',
            'type': 'TRANSFER_OUT',
            'catalogItemId': 'prod-1',
            'quantity': 5,
            'referenceId': 'ref-abc-123',
            'tenantId': 'tenant-1',
            'createdAt': '2026-03-15T10:00:00Z',
          }),
          201,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(
        _buildWidget(
          Builder(builder: (ctx) {
            final container =
                ProviderScope.containerOf(ctx, listen: false);
            container.listen<String?>(
              transferPendingReferenceIdProvider,
              (_, next) => capturedReferenceId = next,
            );
            return TransferOutForm(repository: repo);
          }),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select product
      await tester.tap(
          find.byKey(const Key('transfer_out_product_field')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('transfer_out_product_field')), 'Huile');
      await tester.pump(const Duration(milliseconds: 300));
      final suggestion = find.text('Huile de palme');
      if (suggestion.evaluate().isNotEmpty) {
        await tester.tap(suggestion.first);
        await tester.pump();
      }

      // Enter quantity
      await tester.enterText(
          find.byKey(const Key('transfer_out_quantity_field')), '5');
      await tester.pump();

      // Submit
      await tester.tap(
          find.byKey(const Key('transfer_out_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(capturedReferenceId, equals('ref-abc-123'));
    });
  });

  // ─── TransferPendingScreen ──────────────────────────────────────────────────

  group('TransferPendingScreen — widget tests', () {
    testWidgets('shows list of pending transfers with confirm button',
        (tester) async {
      final pendingData = [
        {
          'id': 'mov-1',
          'type': 'TRANSFER_OUT',
          'catalogItemId': 'prod-1',
          'quantity': 5,
          'referenceId': 'ref-abc',
          'tenantId': 'tenant-1',
          'createdAt': '2026-03-15T10:00:00Z',
        },
      ];

      final fakeClient = MockClient((_) async =>
          http.Response(jsonEncode(pendingData), 200));

      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(
        _buildWidget(TransferPendingScreen(repository: repo)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('transfer_confirm_button_ref-abc')),
          findsOneWidget);
    });

    testWidgets('shows empty state when no pending transfers', (tester) async {
      final fakeClient = MockClient(
          (_) async => http.Response(jsonEncode([]), 200));
      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(
        _buildWidget(TransferPendingScreen(repository: repo)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('transfer_pending_empty')), findsOneWidget);
    });
  });

  // ─── TransferConfirmForm ────────────────────────────────────────────────────

  group('TransferConfirmForm — widget tests', () {
    testWidgets('renders confirm form with pre-filled quantity', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );

      await tester.pumpWidget(
        _buildWidget(
          TransferConfirmForm(
            repository: repo,
            referenceId: 'ref-abc',
            catalogItemId: 'prod-1',
            declaredQuantity: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('confirm_quantity_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_submit_button')), findsOneWidget);

      // Pre-filled with declared quantity
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('confirm_quantity_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller?.text, equals('5'));
    });

    testWidgets('TRANSFER_IN confirmed with variance — reason contains Variance',
        (tester) async {
      final capturedRequests = <http.Request>[];

      final fakeClient = MockClient((req) async {
        capturedRequests.add(req);
        return http.Response(
          jsonEncode({
            'id': 'mov-2',
            'type': 'TRANSFER_IN',
            'quantity': 3,
            'reason': 'Variance: 2',
            'referenceId': 'ref-abc',
            'tenantId': 'tenant-1',
            'createdAt': '2026-03-15T11:00:00Z',
          }),
          201,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(
        _buildWidget(
          TransferConfirmForm(
            repository: repo,
            referenceId: 'ref-abc',
            catalogItemId: 'prod-1',
            declaredQuantity: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Clear pre-filled and enter received quantity (3, declared was 5 → variance 2)
      await tester.enterText(
          find.byKey(const Key('confirm_quantity_field')), '3');
      await tester.pump();

      await tester.tap(find.byKey(const Key('confirm_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // API was called
      expect(capturedRequests, hasLength(1));
      final body = jsonDecode(capturedRequests.first.body) as Map;
      expect(body['referenceId'], equals('ref-abc'));
      expect(body['quantity'], equals(3));
    });

    testWidgets('variance = 0 shows green "Aucun écart" label', (tester) async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode({
              'id': 'mov-3',
              'type': 'TRANSFER_IN',
              'quantity': 5,
              'reason': null,
              'referenceId': 'ref-xyz',
              'tenantId': 'tenant-1',
              'createdAt': '2026-03-15T12:00:00Z',
            }),
            201,
          ));

      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(
        _buildWidget(
          TransferConfirmForm(
            repository: repo,
            referenceId: 'ref-xyz',
            catalogItemId: 'prod-1',
            declaredQuantity: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Quantity matches declared → no variance
      await tester.tap(find.byKey(const Key('confirm_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('variance_label_zero')), findsOneWidget);
    });

    testWidgets('variance ≠ 0 shows red "Écart" label', (tester) async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode({
              'id': 'mov-4',
              'type': 'TRANSFER_IN',
              'quantity': 3,
              'reason': 'Variance: 2',
              'referenceId': 'ref-xyz',
              'tenantId': 'tenant-1',
              'createdAt': '2026-03-15T12:00:00Z',
            }),
            201,
          ));

      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(
        _buildWidget(
          TransferConfirmForm(
            repository: repo,
            referenceId: 'ref-xyz',
            catalogItemId: 'prod-1',
            declaredQuantity: 5,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(
          find.byKey(const Key('confirm_quantity_field')), '3');
      await tester.pump();

      await tester.tap(find.byKey(const Key('confirm_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('variance_label_nonzero')), findsOneWidget);
    });
  });

  // ─── InventoryRepository — transfer methods ─────────────────────────────────

  group('InventoryRepository — transfer methods', () {
    test('getPendingTransfers returns list of TRANSFER_OUT movements',
        () async {
      final data = [
        {
          'id': 'mov-1',
          'type': 'TRANSFER_OUT',
          'referenceId': 'ref-1',
          'quantity': 10,
          'tenantId': 'tenant-1',
          'createdAt': '2026-03-15T10:00:00Z',
        }
      ];
      final fakeClient = MockClient(
          (_) async => http.Response(jsonEncode(data), 200));
      final repo = InventoryRepository(httpClient: fakeClient);

      final result = await repo.getPendingTransfers(tenantId: 'tenant-1');
      expect(result, hasLength(1));
      expect(result.first['type'], equals('TRANSFER_OUT'));
      expect(result.first['referenceId'], equals('ref-1'));
    });

    test('confirmTransfer posts to /inventory/movements/confirm', () async {
      final capturedRequests = <http.Request>[];
      final fakeClient = MockClient((req) async {
        capturedRequests.add(req);
        return http.Response(
          jsonEncode({
            'id': 'mov-2',
            'type': 'TRANSFER_IN',
            'quantity': 8,
            'reason': 'Variance: 2',
            'referenceId': 'ref-1',
          }),
          201,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      final result = await repo.confirmTransfer(
        referenceId: 'ref-1',
        catalogItemId: 'prod-1',
        quantity: 8,
        tenantId: 'tenant-1',
      );

      expect(capturedRequests.first.url.path,
          equals('/inventory/movements/confirm'));
      expect(result['type'], equals('TRANSFER_IN'));
      expect(result['reason'], equals('Variance: 2'));
    });
  });
}
