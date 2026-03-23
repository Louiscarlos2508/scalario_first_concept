import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/shared/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/inventory_screen.dart';
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

Widget _buildScreen(InventoryRepository repo) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      inventoryRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(home: InventoryScreen()),
  );
}

void main() {
  group('InventoryScreen — action chips (pas de TabBar)', () {
    testWidgets('pas de TabBar — les 4 action chips sont présents', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('Réception'), findsOneWidget);
      expect(find.text('Transfert'), findsOneWidget);
      expect(find.text('Perte'), findsOneWidget);
      expect(find.text('Comptage'), findsOneWidget);
    });

    testWidgets('titre AppBar est "Produits & Stock"', (tester) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Produits & Stock'), findsOneWidget);
      expect(find.text('Inventaire'), findsNothing);
    });

    testWidgets('tap chip "Réception" → DeliveryForm visible', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Réception'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('delivery_product_field')), findsOneWidget);
    });

    testWidgets('tap chip "Perte" → LossDeclarationForm visible', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Perte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('loss_product_field')), findsOneWidget);
    });

    testWidgets('tap chip "Transfert" → TransferOutForm visible', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Transfert'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('transfer_out_product_field')),
        findsOneWidget,
      );
    });
  });
}
