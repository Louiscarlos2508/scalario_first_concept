import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/auth/user_profile.dart';
import 'package:frontend/core/models/sync_ui_status.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/retail/inventory/data/models/inventory_movement_local.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';
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

/// In-memory fake that replaces Isar for tests.
class _FakeInventoryRepository extends InventoryRepository {
  final _store = <int, InventoryMovementLocal>{};
  int _nextId = 1;

  _FakeInventoryRepository({super.httpClient});

  @override
  Future<void> saveLocal(InventoryMovementLocal movement) async {
    movement.id = _nextId++;
    _store[movement.id] = movement;
  }

  @override
  Future<List<InventoryMovementLocal>> getPendingMovements() async =>
      _store.values.where((m) => m.syncStatus == 'pending').toList();

  @override
  Future<void> markSynced(int id, String remoteId) async {
    _store[id]
      ?..syncStatus = 'synced'
      ..remoteId = remoteId;
  }

  @override
  Future<void> markFailed(int id, String error) async {
    _store[id]
      ?..syncStatus = 'failed'
      ..errorMessage = error;
  }

  @override
  Future<List<InventoryMovementLocal>> getMovements({
    String? type,
    int limit = 20,
  }) async {
    var results = _store.values.toList();
    if (type != null) results = results.where((m) => m.type == type).toList();
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results.take(limit).toList();
  }

  /// Count of pending movements (for badge test).
  int get pendingCount =>
      _store.values.where((m) => m.syncStatus == 'pending').length;
}

InventoryMovementLocal _makeMovement({String type = 'DELIVERY'}) =>
    InventoryMovementLocal()
      ..type = type
      ..catalogItemId = 'prod-1'
      ..quantity = 5
      ..tenantId = 'tenant-1'
      ..createdAt = DateTime.now()
      ..syncStatus = 'pending';

void main() {
  group('InventoryRepository — offline-first local storage', () {
    test('saveLocal stores movement with syncStatus pending', () async {
      final repo = _FakeInventoryRepository();
      final movement = _makeMovement();

      await repo.saveLocal(movement);

      final pending = await repo.getPendingMovements();
      expect(pending.length, 1);
      expect(pending.first.syncStatus, 'pending');
      expect(pending.first.type, 'DELIVERY');
    });

    test('markSynced sets syncStatus to synced and stores remoteId', () async {
      final repo = _FakeInventoryRepository();
      final movement = _makeMovement();
      await repo.saveLocal(movement);

      await repo.markSynced(movement.id, 'remote-abc');

      final pending = await repo.getPendingMovements();
      expect(pending, isEmpty); // no longer pending
      expect(_store(repo)[movement.id]?.syncStatus, 'synced');
      expect(_store(repo)[movement.id]?.remoteId, 'remote-abc');
    });

    test('markFailed sets syncStatus to failed and stores errorMessage',
        () async {
      final repo = _FakeInventoryRepository();
      final movement = _makeMovement();
      await repo.saveLocal(movement);

      await repo.markFailed(movement.id, 'Network error');

      final pending = await repo.getPendingMovements();
      expect(pending, isEmpty);
      expect(_store(repo)[movement.id]?.syncStatus, 'failed');
      expect(_store(repo)[movement.id]?.errorMessage, 'Network error');
    });

    test('getPendingMovements returns only pending items', () async {
      final repo = _FakeInventoryRepository();
      final m1 = _makeMovement();
      final m2 = _makeMovement(type: 'LOSS');
      await repo.saveLocal(m1);
      await repo.saveLocal(m2);
      await repo.markSynced(m1.id, 'remote-1');

      final pending = await repo.getPendingMovements();
      expect(pending.length, 1);
      expect(pending.first.type, 'LOSS');
    });

    test('badge count is 0 when no pending movements', () async {
      final repo = _FakeInventoryRepository();
      expect(repo.pendingCount, 0);
    });

    test('badge count reflects pending movements', () async {
      final repo = _FakeInventoryRepository();
      await repo.saveLocal(_makeMovement());
      await repo.saveLocal(_makeMovement());
      expect(repo.pendingCount, 2);
    });
  });

  group('InventorySyncAdapter — push pending to server', () {
    test('pushPending syncs DELIVERY movement and calls markSynced', () async {
      final fakeClient = MockClient((req) async {
        if (req.url.path.contains('/inventory/movements')) {
          return http.Response(
            jsonEncode({'id': 'remote-mov-1', 'type': 'DELIVERY'}),
            201,
          );
        }
        return http.Response('{}', 200);
      });

      final repo = _FakeInventoryRepository(httpClient: fakeClient);
      await repo.saveLocal(_makeMovement());

      // Simulate adapter push
      final pending = await repo.getPendingMovements();
      for (final movement in pending) {
        try {
          final result = await repo.createMovement(
            type: movement.type,
            catalogItemId: movement.catalogItemId,
            quantity: movement.quantity,
            reason: movement.reason,
            referenceId: movement.referenceId,
            tenantId: movement.tenantId,
          );
          await repo.markSynced(movement.id, result['id'] as String);
        } catch (e) {
          await repo.markFailed(movement.id, e.toString());
        }
      }

      expect(_store(repo).values.first.syncStatus, 'synced');
      expect(_store(repo).values.first.remoteId, 'remote-mov-1');
    });

    test('pushPending marks as failed on API error', () async {
      final fakeClient = MockClient(
        (_) async => http.Response('{"message":"error"}', 500),
      );

      final repo = _FakeInventoryRepository(httpClient: fakeClient);
      await repo.saveLocal(_makeMovement());

      final pending = await repo.getPendingMovements();
      for (final movement in pending) {
        try {
          final result = await repo.createMovement(
            type: movement.type,
            catalogItemId: movement.catalogItemId,
            quantity: movement.quantity,
            reason: movement.reason,
            referenceId: movement.referenceId,
            tenantId: movement.tenantId,
          );
          await repo.markSynced(movement.id, result['id'] as String);
        } catch (e) {
          await repo.markFailed(movement.id, e.toString());
        }
      }

      expect(_store(repo).values.first.syncStatus, 'failed');
      expect(_store(repo).values.first.errorMessage, isNotNull);
    });
  });

  group('inventoryOutboxCountProvider', () {
    testWidgets('badge count = 0 when no pending via provider override',
        (tester) async {
      final mockProfile = UserProfile(
        id: 'user-1',
        email: 'test@example.com',
        memberships: [TenantMembership(tenantId: 't1', role: 'manager')],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider
                .overrideWith((ref) => Future.value(mockProfile)),
            activeTenantProvider.overrideWith((ref) => 'tenant-1'),
            syncServiceProvider.overrideWithValue(_StubSyncService()),
            inventoryOutboxCountProvider
                .overrideWith((ref) => Stream.value(0)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: _BadgeCountWidget()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('0'), findsOneWidget);
    });
  });
}

/// Helper to access the internal store of the fake repo.
Map<int, InventoryMovementLocal> _store(_FakeInventoryRepository repo) =>
    repo._store;

/// Simple widget that displays the outbox count for testing.
class _BadgeCountWidget extends ConsumerWidget {
  const _BadgeCountWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(inventoryOutboxCountProvider);
    return countAsync.when(
      data: (n) => Text('$n'),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('error'),
    );
  }
}
