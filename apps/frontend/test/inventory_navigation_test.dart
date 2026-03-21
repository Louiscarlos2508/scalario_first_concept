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

Widget _buildScreen(InventoryRepository repo, {int initialIndex = 0}) {
  return ProviderScope(
    overrides: [
      userProfileProvider.overrideWith((ref) => Future.value(_mockProfile)),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      inventoryRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(home: InventoryScreen(initialIndex: initialIndex)),
  );
}

void main() {
  group('InventoryScreen — tab navigation', () {
    testWidgets('TabBar présent avec 6 onglets aux labels corrects', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(6));
      expect(find.text('Produits'), findsNothing);
      expect(find.text('Réceptions'), findsOneWidget);
      expect(find.text('Transferts'), findsOneWidget);
      expect(find.text('Pertes'), findsOneWidget);
      // "Inventaire" appears in AppBar title only (tab is now "Comptage")
      expect(find.text('Inventaire'), findsOneWidget);
      expect(find.text('Comptage'), findsOneWidget);
      expect(find.text('Commandes'), findsOneWidget);
      expect(find.text('Fraîcheur'), findsOneWidget);
    });

    testWidgets('tap onglet "Pertes" → LossDeclarationForm visible', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Pertes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('loss_product_field')), findsOneWidget);
    });

    testWidgets('tap onglet "Réceptions" → DeliveryForm visible', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Réceptions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('delivery_product_field')), findsOneWidget);
    });

    testWidgets('initialIndex: 0 → onglet Réceptions actif par défaut', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo, initialIndex: 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Réceptions tab is active — delivery form is visible without tapping
      expect(find.byKey(const Key('delivery_product_field')), findsOneWidget);
    });

    testWidgets('tap onglet "Transferts" → TransferOutForm visible', (
      tester,
    ) async {
      final repo = InventoryRepository(
        httpClient: MockClient((_) async => http.Response('[]', 200)),
      );
      await tester.pumpWidget(_buildScreen(repo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Transferts'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const Key('transfer_out_product_field')),
        findsOneWidget,
      );
    });
  });
}
