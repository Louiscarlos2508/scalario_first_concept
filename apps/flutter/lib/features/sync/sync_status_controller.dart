import 'dart:async';

import 'sync_status_state.dart';

/// Signal source from `connectivity_plus`. Boolean is enough for the
/// status logic (the controller doesn't care about Wi-Fi vs mobile).
typedef ConnectivitySnapshot = bool;

/// STORY-037 — pure algorithm that combines connectivity, sync queue
/// pending count, and conflict queue pending count into the effective
/// [SyncStatusState].
///
/// Priority (decreasing): conflicts > offline > syncing > synced.
/// This rule is documented in AC-02 and the DS spec.
SyncStatusState computeSyncStatus({
  required bool isOnline,
  required int pendingMutationsCount,
  required int pendingConflictsCount,
  DateTime? lastSyncedAt,
}) {
  if (pendingConflictsCount > 0) {
    return ConflictsPending(count: pendingConflictsCount);
  }
  if (!isOnline) {
    return const Offline();
  }
  if (pendingMutationsCount > 0) {
    return Syncing(pending: pendingMutationsCount);
  }
  return Synced(lastSyncedAt: lastSyncedAt);
}

/// STORY-037 — reactive controller that combines 3 streams (connectivity,
/// sync queue count, conflict queue count) and yields a [SyncStatusState]
/// every time any input changes. Wire this to the BDUI `SyncStatusBar`
/// widget through Riverpod (or your DI framework of choice).
///
/// Phase 1 design: pure Dart, no Flutter dependencies — testable in
/// isolation. The Riverpod adapter is a thin wrapper added in the
/// presentation layer.
class SyncStatusController {
  SyncStatusController({
    required Stream<bool> connectivityStream,
    required Stream<int> pendingMutationsStream,
    required Stream<int> pendingConflictsStream,
    required Future<DateTime?> Function() lastSyncedAtProvider,
  })  : _connectivity = connectivityStream,
        _mutations = pendingMutationsStream,
        _conflicts = pendingConflictsStream,
        _lastSyncedAtProvider = lastSyncedAtProvider;

  final Stream<bool> _connectivity;
  final Stream<int> _mutations;
  final Stream<int> _conflicts;
  final Future<DateTime?> Function() _lastSyncedAtProvider;

  bool _online = true;
  int _mutationCount = 0;
  int _conflictCount = 0;
  DateTime? _lastSyncedAt;

  final _output = StreamController<SyncStatusState>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _disposed = false;

  /// Stream of effective [SyncStatusState]. Subscribers receive the
  /// current state immediately upon subscription via [_emit] + new
  /// states whenever any input changes.
  Stream<SyncStatusState> get stream => _output.stream;

  /// Starts the underlying subscriptions. Call once after construction.
  Future<void> start() async {
    if (_disposed) {
      throw StateError('SyncStatusController already disposed');
    }
    _lastSyncedAt = await _lastSyncedAtProvider();

    _subscriptions.add(_connectivity.listen((online) {
      _online = online;
      _emit();
    }));
    _subscriptions.add(_mutations.listen((count) {
      _mutationCount = count;
      _emit();
    }));
    _subscriptions.add(_conflicts.listen((count) {
      _conflictCount = count;
      _emit();
    }));
    _emit();
  }

  /// Refresh the cached `lastSyncedAt` (e.g. after a successful drain).
  Future<void> refreshLastSyncedAt() async {
    _lastSyncedAt = await _lastSyncedAtProvider();
    _emit();
  }

  void _emit() {
    if (_disposed) return;
    _output.add(computeSyncStatus(
      isOnline: _online,
      pendingMutationsCount: _mutationCount,
      pendingConflictsCount: _conflictCount,
      lastSyncedAt: _lastSyncedAt,
    ));
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _output.close();
  }
}
