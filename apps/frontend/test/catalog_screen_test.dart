import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/catalog/data/repositories/catalog_repository.dart';
import 'package:frontend/features/retail/catalog/presentation/providers/catalog_providers.dart';
import 'package:frontend/features/retail/catalog/presentation/screens/catalog_screen.dart';
import 'package:frontend/features/retail/catalog/presentation/widgets/product_form_dialog.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _buildDialog({
  required http.Client catalogClient,
  http.Client? inventoryClient,
}) {
  final catalogRepo = CatalogRepository(httpClient: catalogClient);
  final inventoryRepo = InventoryRepository(
    httpClient: inventoryClient ?? MockClient((_) async => http.Response('{}', 201)),
  );

  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      catalogRepositoryProvider.overrideWithValue(catalogRepo),
      inventoryRepositoryProvider.overrideWithValue(inventoryRepo),
      categoriesProvider.overrideWith((ref) => Future.value([])),
      catalogProvider.overrideWith((ref) => Future.value([])),
    ],
    child: const MaterialApp(
      home: Scaffold(body: ProductFormDialog(submitToCatalog: true)),
    ),
  );
}

Widget _buildScreen({List<Map<String, dynamic>> items = const []}) {
  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      catalogProvider.overrideWith((ref) => Future.value(items)),
      catalogRepositoryProvider.overrideWithValue(
        CatalogRepository(httpClient: MockClient((_) async => http.Response('[]', 200))),
      ),
    ],
    child: const MaterialApp(home: CatalogScreen()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── ProductFormDialog (submitToCatalog: true) ─────────────────────────────

  group('ProductFormDialog — catalog submit mode', () {
    testWidgets('all fields are present', (tester) async {
      await tester.pumpWidget(
        _buildDialog(catalogClient: MockClient((_) async => http.Response('{}', 201))),
      );
      await tester.pump();

      expect(find.byKey(const Key('product_name_field')), findsOneWidget);
      expect(find.byKey(const Key('product_price_field')), findsOneWidget);
      expect(find.byKey(const Key('product_stock_field')), findsOneWidget);
      expect(find.byKey(const Key('product_barcode_field')), findsOneWidget);
      expect(find.byKey(const Key('product_submit_button')), findsOneWidget);
    });

    testWidgets('name is required — shows error when empty', (tester) async {
      await tester.pumpWidget(
        _buildDialog(catalogClient: MockClient((_) async => http.Response('{}', 201))),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('product_submit_button')));
      await tester.pump();

      expect(find.text('Obligatoire'), findsWidgets);
    });

    testWidgets('price is required — shows error when only name filled',
        (tester) async {
      await tester.pumpWidget(
        _buildDialog(catalogClient: MockClient((_) async => http.Response('{}', 201))),
      );
      await tester.pump();

      await tester.enterText(find.byKey(const Key('product_name_field')), 'Produit X');
      await tester.tap(find.byKey(const Key('product_submit_button')));
      await tester.pump();

      expect(find.text('Obligatoire'), findsOneWidget); // price only
    });

    testWidgets('valid submit calls POST /catalog/items with correct body',
        (tester) async {
      final capturedRequests = <http.Request>[];

      final fakeClient = MockClient((request) async {
        capturedRequests.add(request);
        return http.Response(
          jsonEncode({'id': 'item-new', 'name': 'Farine', 'price': 500, 'tenantId': 'tenant-1'}),
          201,
        );
      });

      await tester.pumpWidget(_buildDialog(catalogClient: fakeClient));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('product_name_field')), 'Farine');
      await tester.enterText(find.byKey(const Key('product_price_field')), '500');

      await tester.tap(find.byKey(const Key('product_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedRequests, hasLength(1));
      final body = jsonDecode(capturedRequests.first.body) as Map;
      expect(body['name'], equals('Farine'));
      expect(body['price'], equals(500.0));
      expect(body['tenantId'], equals('tenant-1'));
    });

    testWidgets('stock > 0 → calls POST /inventory/movements with type DELIVERY',
        (tester) async {
      final catalogRequests = <http.Request>[];
      final inventoryRequests = <http.Request>[];

      final catalogClient = MockClient((req) async {
        catalogRequests.add(req);
        return http.Response(
          jsonEncode({'id': 'item-001', 'name': 'Sucre', 'price': 200, 'tenantId': 'tenant-1'}),
          201,
        );
      });

      final inventoryClient = MockClient((req) async {
        inventoryRequests.add(req);
        return http.Response(jsonEncode({'id': 'mv-001'}), 201);
      });

      await tester.pumpWidget(
        _buildDialog(catalogClient: catalogClient, inventoryClient: inventoryClient),
      );
      await tester.pump();

      await tester.enterText(find.byKey(const Key('product_name_field')), 'Sucre');
      await tester.enterText(find.byKey(const Key('product_price_field')), '200');
      await tester.enterText(find.byKey(const Key('product_stock_field')), '50');

      await tester.tap(find.byKey(const Key('product_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(inventoryRequests, hasLength(1));
      final mvBody = jsonDecode(inventoryRequests.first.body) as Map;
      expect(mvBody['type'], equals('DELIVERY'));
      expect(mvBody['catalogItemId'], equals('item-001'));
      expect(mvBody['quantity'], equals(50));
    });

    testWidgets('shows error snackbar on network failure', (tester) async {
      final fakeClient = MockClient(
        (_) async => http.Response('{"message":"Server error"}', 500),
      );

      await tester.pumpWidget(_buildDialog(catalogClient: fakeClient));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('product_name_field')), 'Farine');
      await tester.enterText(find.byKey(const Key('product_price_field')), '500');

      await tester.tap(find.byKey(const Key('product_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('snackbar_product_error')), findsOneWidget);
    });
  });

  // ── CatalogScreen ─────────────────────────────────────────────────────────

  group('CatalogScreen', () {
    testWidgets('shows empty state when no items', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('catalog_empty_state')), findsOneWidget);
      expect(find.text('Aucun produit dans le catalogue'), findsOneWidget);
    });

    testWidgets('renders item list when catalog has items', (tester) async {
      final items = [
        {'id': 'p1', 'name': 'Farine', 'price': 500},
        {'id': 'p2', 'name': 'Sucre', 'price': 200},
      ];
      await tester.pumpWidget(_buildScreen(items: items));
      await tester.pump();

      expect(find.text('Farine'), findsOneWidget);
      expect(find.text('Sucre'), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_p1')), findsOneWidget);
      expect(find.byKey(const Key('catalog_item_p2')), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();

      expect(find.byKey(const Key('catalog_fab')), findsOneWidget);
    });
  });
}
