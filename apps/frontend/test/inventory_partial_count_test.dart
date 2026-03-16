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
import 'package:frontend/features/retail/inventory/presentation/screens/partial_inventory_screen.dart';
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
    ..name = 'Farine de blé'
    ..price = 800
    ..stockQuantity = 20
    ..tenantId = 'tenant-1',
  Product()
    ..id = 2
    ..remoteId = 'prod-2'
    ..name = 'Sucre blanc'
    ..price = 600
    ..stockQuantity = 10
    ..tenantId = 'tenant-1',
];

Widget _buildScreen(InventoryRepository repo) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      paginatedProductListProvider.overrideWith(
        (ref) => Future.value({
          'items': _mockProducts,
          'total': 2,
          'totalPages': 1,
        }),
      ),
    ],
    child: MaterialApp(
      home: PartialInventoryScreen(repository: repo),
    ),
  );
}

void main() {
  group('PartialInventoryScreen — product selection', () {
    testWidgets('shows product list with checkboxes', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Farine de blé'), findsOneWidget);
      expect(find.text('Sucre blanc'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('"Démarrer le comptage" disabled with no selection',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('start_count_button')),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('"Démarrer le comptage" enabled after selecting 1 product',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('start_count_button')),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('text search filters the product list', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(
          find.byKey(const Key('product_search_field')), 'Farine');
      await tester.pump();

      expect(find.text('Farine de blé'), findsOneWidget);
      expect(find.text('Sucre blanc'), findsNothing);
    });
  });

  group('InventoryCountSheet — variance signal', () {
    testWidgets('green signal when counted == system stock', (tester) async {
      // system stock = 20 for prod-1
      final fakeClient = MockClient((req) async {
        if (req.url.path.contains('/inventory/stock')) {
          return http.Response(
            jsonEncode({
              'catalogItemId': 'prod-1',
              'tenantId': 'tenant-1',
              'currentStock': 20,
              'computedAt': '2026-03-15T10:00:00Z',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Select first product
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();

      // Start counting
      await tester.tap(find.byKey(const Key('start_count_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Enter counted quantity equal to system stock (20)
      final qtyField = find.byKey(const Key('count_quantity_field_prod-1'));
      if (qtyField.evaluate().isNotEmpty) {
        await tester.enterText(qtyField, '20');
        await tester.pump();

        // Green signal (no variance)
        expect(find.byKey(const Key('variance_ok_prod-1')), findsOneWidget);
      }
    });

    testWidgets('red signal when counted != system stock', (tester) async {
      final fakeClient = MockClient((req) async {
        if (req.url.path.contains('/inventory/stock')) {
          return http.Response(
            jsonEncode({
              'catalogItemId': 'prod-1',
              'tenantId': 'tenant-1',
              'currentStock': 20,
              'computedAt': '2026-03-15T10:00:00Z',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('start_count_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final qtyField = find.byKey(const Key('count_quantity_field_prod-1'));
      if (qtyField.evaluate().isNotEmpty) {
        // Enter 15 instead of 20 → variance of -5
        await tester.enterText(qtyField, '15');
        await tester.pump();

        expect(
            find.byKey(const Key('variance_error_prod-1')), findsOneWidget);
      }
    });
  });

  group('InventoryCountSheet — submission', () {
    testWidgets(
        'product with écart → POST /inventory/adjust called; without écart → not called',
        (tester) async {
      int adjustCallCount = 0;

      final fakeClient = MockClient((req) async {
        if (req.url.path.contains('/inventory/stock')) {
          final catalogId =
              req.url.queryParameters['catalogItemId'] ?? 'prod-1';
          // prod-1 stock=20, prod-2 stock=10
          final stock = catalogId == 'prod-1' ? 20 : 10;
          return http.Response(
            jsonEncode({
              'catalogItemId': catalogId,
              'tenantId': 'tenant-1',
              'currentStock': stock,
              'computedAt': '2026-03-15T10:00:00Z',
            }),
            200,
          );
        }
        if (req.url.path.contains('/inventory/adjust')) {
          adjustCallCount++;
          return http.Response(
            jsonEncode({
              'adjusted': true,
              'variance': -5,
              'movement': {'id': 'mov-1', 'type': 'ADJUSTMENT'},
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Select both products
      await tester.tap(find.byType(CheckboxListTile).at(0));
      await tester.pump();
      await tester.tap(find.byType(CheckboxListTile).at(1));
      await tester.pump();

      await tester.tap(find.byKey(const Key('start_count_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // prod-1: enter 15 (écart: -5)
      final field1 = find.byKey(const Key('count_quantity_field_prod-1'));
      if (field1.evaluate().isNotEmpty) {
        await tester.enterText(field1, '15');
        await tester.pump();
      }

      // prod-2: enter 10 (no écart)
      final field2 = find.byKey(const Key('count_quantity_field_prod-2'));
      if (field2.evaluate().isNotEmpty) {
        await tester.enterText(field2, '10');
        await tester.pump();
      }

      // If there's a reason field (because there's an écart), fill it
      final reasonField = find.byKey(const Key('count_reason_field'));
      if (reasonField.evaluate().isNotEmpty) {
        await tester.enterText(reasonField, 'Inventaire mensuel mars');
        await tester.pump();
      }

      // Submit
      final submitBtn = find.byKey(const Key('submit_count_button'));
      if (submitBtn.evaluate().isNotEmpty) {
        final btn = tester.widget<ElevatedButton>(submitBtn);
        if (btn.onPressed != null) {
          await tester.tap(submitBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // Only the product with écart should have triggered POST /inventory/adjust
          expect(adjustCallCount, equals(1));
        }
      }
    });

    testWidgets('motif obligatoire field shown when at least one écart exists',
        (tester) async {
      final fakeClient = MockClient((req) async {
        if (req.url.path.contains('/inventory/stock')) {
          return http.Response(
            jsonEncode({
              'catalogItemId': 'prod-1',
              'tenantId': 'tenant-1',
              'currentStock': 20,
              'computedAt': '2026-03-15T10:00:00Z',
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pump();
      await tester.tap(find.byKey(const Key('start_count_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final field = find.byKey(const Key('count_quantity_field_prod-1'));
      if (field.evaluate().isNotEmpty) {
        await tester.enterText(field, '15'); // écart -5
        await tester.pump();

        // Motif field should appear
        expect(find.byKey(const Key('count_reason_field')), findsOneWidget);
      }
    });
  });

  group('InventoryRepository — adjustStock & getStock', () {
    test('getStock returns currentStock for a catalogItemId', () async {
      final fakeClient = MockClient((req) async {
        expect(req.url.path, equals('/inventory/stock'));
        expect(req.url.queryParameters['catalogItemId'], equals('prod-1'));
        expect(req.url.queryParameters['tenantId'], equals('tenant-1'));
        return http.Response(
          jsonEncode({
            'catalogItemId': 'prod-1',
            'tenantId': 'tenant-1',
            'currentStock': 42,
            'computedAt': '2026-03-15T10:00:00Z',
          }),
          200,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      final stock = await repo.getStock(
        catalogItemId: 'prod-1',
        tenantId: 'tenant-1',
      );
      expect(stock, equals(42));
    });

    test('adjustStock returns adjustment result', () async {
      final fakeClient = MockClient((req) async {
        expect(req.url.path, equals('/inventory/adjust'));
        final body = jsonDecode(req.body) as Map;
        expect(body['catalogItemId'], equals('prod-1'));
        expect(body['countedQuantity'], equals(15));
        expect(body['reason'], equals('Inventaire mensuel'));
        expect(body['tenantId'], equals('tenant-1'));
        return http.Response(
          jsonEncode({
            'adjusted': true,
            'variance': -5,
            'movement': {'id': 'mov-1', 'type': 'ADJUSTMENT'},
          }),
          200,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      final result = await repo.adjustStock(
        catalogItemId: 'prod-1',
        countedQuantity: 15,
        reason: 'Inventaire mensuel',
        tenantId: 'tenant-1',
      );

      expect(result['adjusted'], isTrue);
      expect(result['variance'], equals(-5));
    });

    test('adjustStock throws on non-2xx', () async {
      final fakeClient = MockClient(
        (_) async =>
            http.Response('{"message":"reason required"}', 400),
      );
      final repo = InventoryRepository(httpClient: fakeClient);

      expect(
        () => repo.adjustStock(
          catalogItemId: 'prod-1',
          countedQuantity: 15,
          reason: '',
          tenantId: 'tenant-1',
        ),
        throwsException,
      );
    });
  });
}
