/// STORY-037 — sealed states of the [SyncStatusBar].
///
/// Priority (decreasing): conflicts > offline > syncing > synced.
/// The `SyncStatusBar` widget (component DS) renders these as 4 visual
/// variants per [SyncStatusBar] DS spec (see
/// `design-process/D-Design-System/components/01-feedback.md`).
sealed class SyncStatusState {
  const SyncStatusState();
}

/// "À jour — il y a Xmin" (success-500, discreet).
class Synced extends SyncStatusState {
  const Synced({this.lastSyncedAt});
  final DateTime? lastSyncedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Synced && other.lastSyncedAt == lastSyncedAt);

  @override
  int get hashCode => Object.hash('Synced', lastSyncedAt);

  @override
  String toString() => 'Synced(lastSyncedAt: $lastSyncedAt)';
}

/// "Synchronisation… (N restantes)" (primary-500, animated).
class Syncing extends SyncStatusState {
  const Syncing({required this.pending});
  final int pending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Syncing && other.pending == pending);

  @override
  int get hashCode => Object.hash('Syncing', pending);

  @override
  String toString() => 'Syncing(pending: $pending)';
}

/// "Hors ligne — données locales à jour" (neutral-500, NEVER red — DS rule).
class Offline extends SyncStatusState {
  const Offline();

  @override
  bool operator ==(Object other) => other is Offline;

  @override
  int get hashCode => 'Offline'.hashCode;

  @override
  String toString() => 'Offline()';
}

/// "N conflit(s) en attente — toucher pour résoudre" (warning-500 + badge).
class ConflictsPending extends SyncStatusState {
  const ConflictsPending({required this.count});
  final int count;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictsPending && other.count == count);

  @override
  int get hashCode => Object.hash('ConflictsPending', count);

  @override
  String toString() => 'ConflictsPending(count: $count)';
}
