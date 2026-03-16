import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/dashboard/data/repositories/inventory_repository.dart';
import 'package:frontend/features/retail/dashboard/presentation/widgets/inventory/loss_declaration_form.dart';
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
    ..name = 'Tomates'
    ..price = 500
    ..stockQuantity = 15
    ..tenantId = 'tenant-1',
];

Widget _buildForm(InventoryRepository repo) {
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
    ],
    child: MaterialApp(
      home: Scaffold(body: LossDeclarationForm(repository: repo)),
    ),
  );
}

void main() {
  group('LossDeclarationForm — widget tests', () {
    testWidgets('renders all form fields: product, quantity, reason dropdown',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('loss_product_field')), findsOneWidget);
      expect(find.byKey(const Key('loss_quantity_field')), findsOneWidget);
      expect(find.byKey(const Key('loss_reason_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('loss_submit_button')), findsOneWidget);
    });

    testWidgets('dropdown has 5 reason options', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Open the dropdown
      await tester.tap(find.byKey(const Key('loss_reason_dropdown')));
      await tester.pumpAndSettle();

      expect(find.text('Casse'), findsWidgets);
      expect(find.text('Péremption'), findsWidgets);
      expect(find.text('Vol'), findsWidgets);
      expect(find.text('Frotte'), findsWidgets);
      expect(find.text('Autre'), findsWidgets);
    });

    testWidgets('submit button disabled when no motif selected', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Enter quantity but no reason
      await tester.enterText(
          find.byKey(const Key('loss_quantity_field')), '3');
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('loss_submit_button')),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets(
        '"Autre" selected → text precision field appears and is required',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select "Autre" from dropdown
      await tester.tap(find.byKey(const Key('loss_reason_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autre').last);
      await tester.pumpAndSettle();

      // Precision field should now be visible
      expect(
          find.byKey(const Key('loss_reason_autre_field')), findsOneWidget);
    });

    testWidgets(
        'submit with motif Casse + quantity 3 → POST LOSS with reason Casse',
        (tester) async {
      final capturedRequests = <http.Request>[];
      final fakeClient = MockClient((req) async {
        capturedRequests.add(req);
        return http.Response(
          jsonEncode({
            'id': 'mov-1',
            'type': 'LOSS',
            'catalogItemId': 'prod-1',
            'quantity': 3,
            'reason': 'Casse',
            'tenantId': 'tenant-1',
          }),
          201,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select product
      await tester.tap(find.byKey(const Key('loss_product_field')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('loss_product_field')), 'Tom');
      await tester.pump(const Duration(milliseconds: 300));
      final sug = find.text('Tomates');
      if (sug.evaluate().isNotEmpty) {
        await tester.tap(sug.first);
        await tester.pump();
      }

      // Enter quantity
      await tester.enterText(
          find.byKey(const Key('loss_quantity_field')), '3');
      await tester.pump();

      // Select reason Casse
      await tester.tap(find.byKey(const Key('loss_reason_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Casse').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byKey(const Key('loss_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(capturedRequests, hasLength(1));
      final body = jsonDecode(capturedRequests.first.body) as Map;
      expect(body['type'], equals('LOSS'));
      expect(body['reason'], equals('Casse'));
      expect(body['quantity'], equals(3));
      expect(body['tenantId'], equals('tenant-1'));
    });

    testWidgets(
        '"Autre" without precision → submit stays disabled',
        (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('{}', 201)),
      );
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select product
      await tester.tap(find.byKey(const Key('loss_product_field')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('loss_product_field')), 'Tom');
      await tester.pump(const Duration(milliseconds: 300));
      final sug = find.text('Tomates');
      if (sug.evaluate().isNotEmpty) {
        await tester.tap(sug.first);
        await tester.pump();
      }

      await tester.enterText(
          find.byKey(const Key('loss_quantity_field')), '2');
      await tester.pump();

      // Select "Autre" but leave precision empty
      await tester.tap(find.byKey(const Key('loss_reason_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autre').last);
      await tester.pumpAndSettle();

      final btn = tester.widget<ElevatedButton>(
        find.byKey(const Key('loss_submit_button')),
      );
      // No precision → still disabled
      expect(btn.onPressed, isNull);
    });

    testWidgets(
        '"Autre" + precision → reason sent as "Autre : {précision}"',
        (tester) async {
      final capturedRequests = <http.Request>[];
      final fakeClient = MockClient((req) async {
        capturedRequests.add(req);
        return http.Response(
          jsonEncode({
            'id': 'mov-2',
            'type': 'LOSS',
            'catalogItemId': 'prod-1',
            'quantity': 1,
            'reason': 'Autre : Chute en entrepôt',
            'tenantId': 'tenant-1',
          }),
          201,
        );
      });

      final repo = InventoryRepository(httpClient: fakeClient);
      await tester.pumpWidget(_buildForm(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Select product
      await tester.tap(find.byKey(const Key('loss_product_field')));
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('loss_product_field')), 'Tom');
      await tester.pump(const Duration(milliseconds: 300));
      final sug = find.text('Tomates');
      if (sug.evaluate().isNotEmpty) {
        await tester.tap(sug.first);
        await tester.pump();
      }

      await tester.enterText(
          find.byKey(const Key('loss_quantity_field')), '1');
      await tester.pump();

      await tester.tap(find.byKey(const Key('loss_reason_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autre').last);
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('loss_reason_autre_field')),
          'Chute en entrepôt');
      await tester.pump();

      await tester.tap(find.byKey(const Key('loss_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(capturedRequests, hasLength(1));
      final body = jsonDecode(capturedRequests.first.body) as Map;
      expect(body['reason'], equals('Autre : Chute en entrepôt'));
    });
  });
}
