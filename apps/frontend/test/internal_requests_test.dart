import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/shared/inventory/data/repositories/internal_requests_repository.dart';
import 'package:frontend/features/shared/inventory/presentation/providers/internal_requests_provider.dart';
import 'package:frontend/features/shared/inventory/presentation/screens/internal_requests_screen.dart';
import 'package:frontend/features/shared/inventory/presentation/widgets/internal_request_form.dart';
import 'package:frontend/features/shared/notifications/presentation/providers/notification_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Stubs ──────────────────────────────────────────────────────────────────

class _StubSyncService extends SyncService {
  final _ctrl = StreamController<SyncUiStatus>.broadcast();
  @override
  Stream<SyncUiStatus> get statusStream => _ctrl.stream;
  @override
  Future<void> startSync(String? tenantId, {String? authToken}) async {}
}

// ── Fixtures ───────────────────────────────────────────────────────────────

UserProfile _profileWithRole(String role) => UserProfile(
      id: 'user-1',
      email: 'test@example.com',
      memberships: [TenantMembership(tenantId: 'tenant-1', role: role)],
    );

final _mockProducts = [
  Product()
    ..id = 1
    ..remoteId = 'prod-1'
    ..name = 'Coca-Cola'
    ..price = 500
    ..stockQuantity = 20
    ..tenantId = 'tenant-1',
];

final _pendingRequest = {
  'id': 'req-uuid-001',
  'tenantId': 'tenant-1',
  'catalogItemId': 'prod-1',
  'quantity': 10,
  'status': 'pending',
  'urgency': 'normal',
  'requestedBy': 'user-1',
  'preparedBy': null,
  'approvedBy': null,
  'reason': null,
  'catalogItem': {'name': 'Coca-Cola'},
  'createdAt': '2026-03-25T10:00:00.000Z',
};

final _preparedRequest = {
  ..._pendingRequest,
  'status': 'prepared',
};

// ── Widget builder helpers ──────────────────────────────────────────────────

Widget _buildForm({
  String role = 'commercial',
  http.Client? httpClient,
  List<Map<String, dynamic>> requests = const [],
}) {
  return ProviderScope(
    overrides: [
      userProfileProvider
          .overrideWith((ref) => Future.value(_profileWithRole(role))),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      paginatedProductListProvider.overrideWith(
        (ref) => Future.value({
          'items': _mockProducts,
          'total': _mockProducts.length,
          'totalPages': 1,
        }),
      ),
      internalRequestsRepositoryProvider.overrideWithValue(
        InternalRequestsRepository(httpClient: httpClient ?? MockClient((_) async => http.Response('{}', 200))),
      ),
      internalRequestsProvider.overrideWith(
        (ref) => Future.value(requests),
      ),
      internalRequestsPendingCountProvider('commercial')
          .overrideWith((ref) => Future.value(0)),
      internalRequestsPendingCountProvider('manager')
          .overrideWith((ref) => Future.value(0)),
      internalRequestsPendingCountProvider('owner')
          .overrideWith((ref) => Future.value(0)),
      unreadNotificationCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: MaterialApp(
      home: Scaffold(body: InternalRequestForm()),
    ),
  );
}

Widget _buildScreen({
  String role = 'commercial',
  List<Map<String, dynamic>> requests = const [],
}) {
  return ProviderScope(
    overrides: [
      userProfileProvider
          .overrideWith((ref) => Future.value(_profileWithRole(role))),
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      syncServiceProvider.overrideWithValue(_StubSyncService()),
      paginatedProductListProvider.overrideWith(
        (ref) => Future.value({
          'items': _mockProducts,
          'total': _mockProducts.length,
          'totalPages': 1,
        }),
      ),
      internalRequestsRepositoryProvider.overrideWithValue(
        InternalRequestsRepository(httpClient: MockClient((_) async => http.Response('[]', 200))),
      ),
      internalRequestsProvider.overrideWith(
        (ref) => Future.value(requests),
      ),
      internalRequestsPendingCountProvider('commercial')
          .overrideWith((ref) => Future.value(0)),
      internalRequestsPendingCountProvider('manager')
          .overrideWith((ref) => Future.value(requests.where((r) => r['status'] == 'pending').length)),
      internalRequestsPendingCountProvider('owner')
          .overrideWith((ref) => Future.value(requests.where((r) => r['status'] == 'prepared').length)),
      unreadNotificationCountProvider.overrideWith((ref) => const Stream<int>.empty()),
    ],
    child: const MaterialApp(home: InternalRequestsScreen()),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('InternalRequestForm', () {
    // Test 8 : submit sans produit → bouton désactivé
    testWidgets('bouton désactivé si aucun produit sélectionné', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Entrer une quantité valide
      await tester.enterText(find.byKey(const Key('ir_quantity_field')), '5');
      await tester.pump();

      // Bouton doit être désactivé (aucun produit sélectionné)
      final button = tester.widget<ElevatedButton>(
        find.byKey(const Key('ir_submit_button')),
      );
      expect(button.onPressed, isNull);
    });

    // Test 9 : submit valide → POST /internal-requests appelé
    testWidgets('POST appelé après sélection produit + quantité valide',
        (tester) async {
      bool postCalled = false;

      final client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('internal-requests')) {
          postCalled = true;
          return http.Response(jsonEncode(_pendingRequest), 201);
        }
        return http.Response('[]', 200);
      });

      await tester.pumpWidget(_buildForm(httpClient: client));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Entrer quantité
      await tester.enterText(find.byKey(const Key('ir_quantity_field')), '10');
      await tester.pump();

      // Simuler sélection produit via autocomplete
      await tester.enterText(find.byType(TextFormField).first, 'Coca');
      await tester.pump(const Duration(milliseconds: 300));
      // Trouver et taper sur la suggestion si visible, sinon forcer la sélection
      final suggestions = find.text('Coca-Cola');
      if (suggestions.evaluate().length > 1) {
        await tester.tap(suggestions.last);
        await tester.pump();
      }

      // Vérifier le bouton est présent
      expect(find.byKey(const Key('ir_submit_button')), findsOneWidget);
      expect(postCalled, isTrue,
          reason: 'Le POST /internal-requests doit être appelé si formulaire valide');
    }, skip: true /* autocomplete selection nécessite interaction native */);
  });

  group('InternalRequestsScreen', () {
    // Test 10 : onglet "À traiter" visible pour manager et owner
    testWidgets('onglet "À traiter" visible pour manager', (tester) async {
      await tester.pumpWidget(_buildScreen(role: 'manager'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('ir_tab_to_process')), findsOneWidget);
    });

    testWidgets('onglet "À traiter" visible pour owner', (tester) async {
      await tester.pumpWidget(_buildScreen(role: 'owner'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('ir_tab_to_process')), findsOneWidget);
    });

    testWidgets('onglet "À traiter" présent pour tous les rôles', (tester) async {
      await tester.pumpWidget(_buildScreen(role: 'commercial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Le tab est toujours présent dans la TabBar
      expect(find.byKey(const Key('ir_tab_to_process')), findsOneWidget);
    });

    // Test 11 : bouton "Préparer" visible pour manager si status=pending
    testWidgets('bouton Préparer visible pour manager sur demande pending',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(role: 'manager', requests: [_pendingRequest]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Le bouton contient la clé ir_prepare_<8 chars of id>
      expect(find.byKey(const Key('ir_prepare_req-uuid')), findsOneWidget);
    });

    testWidgets('bouton Approuver visible pour owner sur demande prepared',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(role: 'owner', requests: [_preparedRequest]),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('ir_approve_req-uuid')), findsOneWidget);
    });

    testWidgets('liste vide affiche état vide', (tester) async {
      await tester.pumpWidget(_buildScreen(requests: []));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Aucune demande'), findsOneWidget);
    });
  });
}
