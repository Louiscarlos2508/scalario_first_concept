import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../database.dart';

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

  // --- STORY-034: Sync queue worker methods ---

  Future<List<SyncQueueItem>> fetchEligible({
    required String tenantId,
    required DateTime now,
    int limit = 20,
  }) async {
    final query = await customSelect(
      'SELECT * FROM sync_queue_items '
      'WHERE tenant_id = ? '
      'AND (status = \'pending\' '
      'OR (status = \'error\' AND next_retry_at <= ?)) '
      'ORDER BY created_at ASC, mutation_id ASC '
      'LIMIT ?',
      variables: [
        Variable.withString(tenantId),
        Variable.withString(now.toIso8601String()),
        Variable.withInt(limit),
      ],
      readsFrom: {db.syncQueueItems},
    ).get();

    return query.map((row) {
      final data = row.data;

      // ignore: no_leading_underscores_for_local_identifiers
      DateTime _parseDate(dynamic value) {
        if (value is String) return DateTime.parse(value);
        if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
        developer.log(
          'fetchEligible: unexpected type ${value.runtimeType} for date column, falling back to epoch',
          name: 'Scalario.Offline.DAO',
          level: 900,
        );
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      return SyncQueueItem(
        mutationId: data['mutation_id'].toString(),
        tenantId: data['tenant_id'].toString(),
        moduleId: data['module_id'].toString(),
        action: data['action'].toString(),
        payloadJson: data['payload_json'].toString(),
        idempotencyKey: data['idempotency_key'].toString(),
        createdAt: _parseDate(data['created_at']),
        retryCount: data['retry_count'] == null
            ? 0
            : data['retry_count'] is int
                ? data['retry_count'] as int
                : int.tryParse(data['retry_count'].toString()) ?? 0,
        status: data['status'].toString(),
        lastError: data['last_error']?.toString(),
        nextRetryAt: data['next_retry_at'] != null
            ? _parseDate(data['next_retry_at'])
            : null,
      );
    }).toList();
  }

  Future<void> markSending(List<String> mutationIds) {
    if (mutationIds.isEmpty) return Future<void>.value();
    final placeholders = mutationIds.map((_) => '?').join(',');
    return customStatement(
      'UPDATE sync_queue_items SET status = \'sending\' '
      'WHERE mutation_id IN ($placeholders)',
      mutationIds,
    );
  }

  Future<void> markSuccess(String mutationId) =>
      (update(db.syncQueueItems)
            ..where((t) => t.mutationId.equals(mutationId)))
          .write(const SyncQueueItemsCompanion(status: Value('success')));

  Future<void> markConflict(String mutationId, {String? error}) =>
      (update(db.syncQueueItems)
            ..where((t) => t.mutationId.equals(mutationId)))
          .write(SyncQueueItemsCompanion(
            status: const Value('conflict'),
            lastError: Value(error),
          ));

  Future<void> markErrorWithBackoff({
    required String mutationId,
    required String error,
    required DateTime nextRetryAt,
  }) async {
    await customStatement(
      'UPDATE sync_queue_items SET status = \'error\', '
      'last_error = ?, next_retry_at = ?, retry_count = retry_count + 1 '
      'WHERE mutation_id = ?',
      [error, nextRetryAt.toIso8601String(), mutationId],
    );
  }

  Future<void> markPermanentError(String mutationId, {required String error}) =>
      (update(db.syncQueueItems)
            ..where((t) => t.mutationId.equals(mutationId)))
          .write(SyncQueueItemsCompanion(
            status: const Value('error'),
            lastError: Value(error),
          ));

  Future<void> recoverInFlight({required String tenantId}) =>
      customStatement(
        'UPDATE sync_queue_items SET status = \'pending\' '
        'WHERE status = \'sending\' AND tenant_id = ?',
        [tenantId],
      );
}
