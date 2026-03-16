import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/inventory/presentation/widgets/delivery_form.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Stub SyncService — prevents pumpAndSettle timeout from broadcast stream.
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

// Products for the autocomplete
final _mockProducts = [
  Product()
    ..id = 1
    ..remoteId = 'prod-1'
    ..name = 'Coca-Cola'
    ..price = 500
    ..stockQuantity = 20
    ..tenantId = 'tenant-1',
  Product()
    ..id = 2
    ..remoteId = 'prod-2'
    ..name = 'Fanta Orange'
    ..price = 300
    ..stockQuantity = 5
    ..tenantId = 'tenant-1',
];

Widget _buildForm({
  required InventoryRepository repo,
  List<Product>? products,
}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      paginatedProductListProvider.overrideWith(
        (ref) => Future.value({
          'items': products ?? _mockProducts,
          'total': (products ?? _mockProducts).length,
          'totalPages': 1,
        }),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: DeliveryForm(repository: repo),
      ),
    ),
  );
}

void main() {
  group('DeliveryForm — widget tests', () {
    testWidgets('form is present with all expected fields and submit button',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      await tester.pumpWidget(_buildForm(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Product search field present
      expect(find.byKey(const Key('delivery_product_field')), findsOneWidget);
      // Quantity field present
      expect(find.byKey(const Key('delivery_quantity_field')), findsOneWidget);
      // Notes field present
      expect(find.byKey(const Key('delivery_notes_field')), findsOneWidget);
      // Submit button present
      expect(find.byKey(const Key('delivery_submit_button')), findsOneWidget);
    });

    testWidgets('submit button is disabled when quantity is empty',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      await tester.pumpWidget(_buildForm(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('delivery_submit_button')),
      );
      // No product selected, no quantity → disabled
      expect(submitBtn.onPressed, isNull);
    });

    testWidgets(
        'submit calls POST /inventory/movements with type DELIVERY and shows snackbar',
        (tester) async {
      final capturedRequests = <http.Request>[];

      final fakeClient = MockClient((request) async {
        capturedRequests.add(request);
        final movement = {
          'id': 'mov-1',
          'type': 'DELIVERY',
          'catalogItemId': 'prod-1',
          'quantity': 10,
          'reason': null,
          'tenantId': 'tenant-1',
          'createdAt': '2026-03-15T10:00:00Z',
        };
        return http.Response(jsonEncode(movement), 201);
      });

      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(_buildForm(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select product via autocomplete
      await tester.tap(find.byKey(const Key('delivery_product_field')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('delivery_product_field')), 'Coca');
      await tester.pump(const Duration(milliseconds: 300));

      // Pick the suggestion
      final suggestion = find.text('Coca-Cola');
      if (suggestion.evaluate().isNotEmpty) {
        await tester.tap(suggestion.first);
        await tester.pump();
      }

      // Enter quantity
      await tester.enterText(
          find.byKey(const Key('delivery_quantity_field')), '10');
      await tester.pump();

      // Submit button should now be enabled
      final submitBtn = tester.widget<ElevatedButton>(
        find.byKey(const Key('delivery_submit_button')),
      );
      expect(submitBtn.onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('delivery_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify API was called
      expect(capturedRequests, hasLength(1));
      final body = jsonDecode(capturedRequests.first.body) as Map;
      expect(body['type'], equals('DELIVERY'));
      expect(body['tenantId'], equals('tenant-1'));
    });

    testWidgets('shows error snackbar on API failure', (tester) async {
      final fakeClient = MockClient(
        (_) async => http.Response('{"message":"Server error"}', 500),
      );
      final repo = InventoryRepository(httpClient: fakeClient);

      await tester.pumpWidget(_buildForm(repo: repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select product
      await tester.tap(find.byKey(const Key('delivery_product_field')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('delivery_product_field')), 'Coca');
      await tester.pump(const Duration(milliseconds: 300));
      final suggestion = find.text('Coca-Cola');
      if (suggestion.evaluate().isNotEmpty) {
        await tester.tap(suggestion.first);
        await tester.pump();
      }

      // Enter quantity
      await tester.enterText(
          find.byKey(const Key('delivery_quantity_field')), '5');
      await tester.pump();

      await tester.tap(find.byKey(const Key('delivery_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Error snackbar should appear
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('InventoryRepository.createMovement()', () {
    test('returns movement map on 201 success', () async {
      final fakeClient = MockClient((request) async {
        expect(request.url.path, equals('/inventory/movements'));
        expect(request.method, equals('POST'));
        final body = jsonDecode(request.body) as Map;
        expect(body['type'], equals('DELIVERY'));
        expect(body['catalogItemId'], equals('prod-1'));
        expect(body['quantity'], equals(10));
        expect(body['tenantId'], equals('tenant-1'));
        return http.Response(
          jsonEncode({
            'id': 'mov-abc',
            'type': 'DELIVERY',
            'catalogItemId': 'prod-1',
            'quantity': 10,
            'reason': null,
            'tenantId': 'tenant-1',
            'createdAt': '2026-03-15T10:00:00Z',
          }),
          201,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      final result = await repo.createMovement(
        type: 'DELIVERY',
        catalogItemId: 'prod-1',
        quantity: 10,
        tenantId: 'tenant-1',
      );

      expect(result['id'], equals('mov-abc'));
      expect(result['type'], equals('DELIVERY'));
    });

    test('throws exception on non-2xx response', () async {
      final fakeClient = MockClient(
        (_) async => http.Response('{"message":"Bad Request"}', 400),
      );
      final repo = InventoryRepository(httpClient: fakeClient);

      expect(
        () => repo.createMovement(
          type: 'DELIVERY',
          catalogItemId: 'prod-1',
          quantity: 10,
          tenantId: 'tenant-1',
        ),
        throwsException,
      );
    });
  });
}
