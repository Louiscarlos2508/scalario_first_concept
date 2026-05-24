import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/features/sync/sync_status_controller.dart';
import 'package:scalario/features/sync/sync_status_state.dart';

void main() {
  group('AC-02 — computeSyncStatus priority algorithm (conflicts > offline > syncing > synced)', () {
    test('conflicts > 0 always wins (even if offline)', () {
      expect(
        computeSyncStatus(
          isOnline: false,
          pendingMutationsCount: 5,
          pendingConflictsCount: 2,
        ),
        const ConflictsPending(count: 2),
      );
    });

    test('conflicts > 0 always wins (even if online + draining)', () {
      expect(
        computeSyncStatus(
          isOnline: true,
          pendingMutationsCount: 10,
          pendingConflictsCount: 1,
        ),
        const ConflictsPending(count: 1),
      );
    });

    test('offline beats syncing when no conflicts', () {
      // While offline, the queue accumulates but we are not "syncing".
      expect(
        computeSyncStatus(
          isOnline: false,
          pendingMutationsCount: 5,
          pendingConflictsCount: 0,
        ),
        const Offline(),
      );
    });

    test('online + pending mutations + no conflicts → Syncing', () {
      expect(
        computeSyncStatus(
          isOnline: true,
          pendingMutationsCount: 3,
          pendingConflictsCount: 0,
        ),
        const Syncing(pending: 3),
      );
    });

    test('online + 0 pending + 0 conflicts → Synced (default)', () {
      final synced = computeSyncStatus(
        isOnline: true,
        pendingMutationsCount: 0,
        pendingConflictsCount: 0,
      );
      expect(synced, isA<Synced>());
      expect((synced as Synced).lastSyncedAt, isNull);
    });

    test('Synced carries lastSyncedAt when provided', () {
      final ts = DateTime.utc(2026, 5, 24, 18, 0);
      final synced = computeSyncStatus(
        isOnline: true,
        pendingMutationsCount: 0,
        pendingConflictsCount: 0,
        lastSyncedAt: ts,
      );
      expect(synced, isA<Synced>());
      expect((synced as Synced).lastSyncedAt, ts);
    });
  });

  group('AC-01 — SyncStatusController combines 3 reactive sources', () {
    late StreamController<bool> connectivity;
    late StreamController<int> mutations;
    late StreamController<int> conflicts;
    late SyncStatusController controller;

    setUp(() {
      connectivity = StreamController<bool>.broadcast();
      mutations = StreamController<int>.broadcast();
      conflicts = StreamController<int>.broadcast();
      controller = SyncStatusController(
        connectivityStream: connectivity.stream,
        pendingMutationsStream: mutations.stream,
        pendingConflictsStream: conflicts.stream,
        lastSyncedAtProvider: () async => null,
      );
    });

    tearDown(() async {
      await controller.dispose();
      await connectivity.close();
      await mutations.close();
      await conflicts.close();
    });

    test('emits Synced on start when all inputs are clean', () async {
      final emissions = <SyncStatusState>[];
      final sub = controller.stream.listen(emissions.add);
      await controller.start();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions.first, isA<Synced>());
    });

    test('transitions Synced → Offline when connectivity drops', () async {
      final emissions = <SyncStatusState>[];
      final sub = controller.stream.listen(emissions.add);
      await controller.start();
      connectivity.add(false);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions.last, const Offline());
    });

    test('transitions Offline → Syncing when reconnects with pending', () async {
      final emissions = <SyncStatusState>[];
      final sub = controller.stream.listen(emissions.add);
      await controller.start();
      connectivity.add(false);
      mutations.add(7); // pending while offline
      connectivity.add(true);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions.last, const Syncing(pending: 7));
    });

    test('Syncing → ConflictsPending takes precedence', () async {
      final emissions = <SyncStatusState>[];
      final sub = controller.stream.listen(emissions.add);
      await controller.start();
      mutations.add(3);
      await Future<void>.delayed(Duration.zero);
      expect(emissions.last, const Syncing(pending: 3));
      conflicts.add(2);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions.last, const ConflictsPending(count: 2));
    });

    test('refreshLastSyncedAt re-emits with the latest timestamp', () async {
      // Dispose the auto-created controller from setUp; build a fresh one
      // wired to a moving lastSyncedAt provider.
      await controller.dispose();
      var latest = DateTime.utc(2026, 5, 24, 18, 0);
      controller = SyncStatusController(
        connectivityStream: connectivity.stream,
        pendingMutationsStream: mutations.stream,
        pendingConflictsStream: conflicts.stream,
        lastSyncedAtProvider: () async => latest,
      );
      final emissions = <SyncStatusState>[];
      final sub = controller.stream.listen(emissions.add);
      await controller.start();
      await Future<void>.delayed(Duration.zero);
      expect((emissions.last as Synced).lastSyncedAt, latest);

      latest = DateTime.utc(2026, 5, 24, 18, 30);
      await controller.refreshLastSyncedAt();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect((emissions.last as Synced).lastSyncedAt, latest);
    });

    test('disposed controller throws on start', () async {
      await controller.dispose();
      expect(() => controller.start(), throwsStateError);
    });
  });

  group('AC-24 — 4 documented input combinations', () {
    test('(offline, queue=0, conflicts=0) → Offline', () {
      expect(
        computeSyncStatus(
          isOnline: false,
          pendingMutationsCount: 0,
          pendingConflictsCount: 0,
        ),
        const Offline(),
      );
    });

    test('(online, queue=5, conflicts=0) → Syncing(5)', () {
      expect(
        computeSyncStatus(
          isOnline: true,
          pendingMutationsCount: 5,
          pendingConflictsCount: 0,
        ),
        const Syncing(pending: 5),
      );
    });

    test('(online, queue=0, conflicts=2) → ConflictsPending(2)', () {
      expect(
        computeSyncStatus(
          isOnline: true,
          pendingMutationsCount: 0,
          pendingConflictsCount: 2,
        ),
        const ConflictsPending(count: 2),
      );
    });

    test('(online, queue=0, conflicts=0) → Synced', () {
      expect(
        computeSyncStatus(
          isOnline: true,
          pendingMutationsCount: 0,
          pendingConflictsCount: 0,
        ),
        isA<Synced>(),
      );
    });
  });

  group('SyncStatusState value equality', () {
    test('Synced equals by lastSyncedAt', () {
      final ts = DateTime(2026, 5, 24);
      expect(Synced(lastSyncedAt: ts) == Synced(lastSyncedAt: ts), true);
      expect(const Synced() == const Synced(), true);
    });

    test('Syncing equals by pending count', () {
      expect(const Syncing(pending: 3) == const Syncing(pending: 3), true);
      expect(const Syncing(pending: 3) == const Syncing(pending: 4), false);
    });

    test('Offline is a singleton-equivalent', () {
      expect(const Offline() == const Offline(), true);
    });

    test('ConflictsPending equals by count', () {
      expect(
        const ConflictsPending(count: 2) == const ConflictsPending(count: 2),
        true,
      );
    });
  });
}
