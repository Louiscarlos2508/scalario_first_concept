import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/sync_queue_items.dart';

/// DAO pour [SyncQueueItems] — FIFO queue de mutations offline.
///
/// AC-07 : index `(status, createdAt)` pour extraction FIFO.
/// Le moteur de sync (STORY-034) consomme ces entrées.
final class SyncQueueDao extends DatabaseAccessor<ScalarioDatabase> {
  SyncQueueDao(super.attachedDatabase);

  Future<SyncQueueItem?> getNextPending() =>
      (select(db.syncQueueItems)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<SyncQueueItem>> getPending(String tenantId) =>
      (select(db.syncQueueItems)
            ..where((t) =>
                t.tenantId.equals(tenantId) & t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .get();

  Future<int> pendingCount(String tenantId) =>
      (selectOnly(db.syncQueueItems)
            ..addColumns([countAll()])
            ..where(db.syncQueueItems.tenantId.equals(tenantId) &
                db.syncQueueItems.status.equals('pending')))
          .map((row) => row.read(countAll())!)
          .getSingle();

  Future<void> insert(SyncQueueItemsCompanion item) =>
      into(db.syncQueueItems).insert(item);

  Future<void> markCompleted(String mutationId) =>
      (update(db.syncQueueItems)
            ..where((t) => t.mutationId.equals(mutationId)))
          .write(
            const SyncQueueItemsCompanion(status: Value('completed')),
          );

  Future<void> markFailed(String mutationId, {String? error}) async {
    await customStatement(
      'UPDATE sync_queue_items SET status = \'failed\', '
      'last_error = ?, retry_count = retry_count + 1 '
      'WHERE mutation_id = ?',
      [error, mutationId],
    );
  }

  Future<void> deleteCompleted() =>
      (delete(db.syncQueueItems)
            ..where((t) => t.status.equals('completed')))
          .go();
}
