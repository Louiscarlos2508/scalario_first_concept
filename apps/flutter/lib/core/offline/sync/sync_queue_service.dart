import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../dao/local_data_dao.dart';
import '../dao/sync_queue_dao.dart';
import '../database.dart';

class SyncQueueService {
  SyncQueueService({
    required SyncQueueDao queueDao,
    required LocalDataDao localDataDao,
    Uuid? uuid,
  })  : _queueDao = queueDao,
        _localDataDao = localDataDao,
        _uuid = uuid ?? const Uuid();

  final SyncQueueDao _queueDao;
  final LocalDataDao _localDataDao;
  final Uuid _uuid;

  final StreamController<void> _onEnqueuedController =
      StreamController<void>.broadcast();

  Stream<void> get onEnqueued => _onEnqueuedController.stream;

  Future<String> enqueue({
    required String tenantId,
    required String moduleId,
    required String action,
    required Map<String, dynamic> payload,
    String? entityId,
  }) async {
    final mutationId = _uuid.v4();
    final stopwatch = Stopwatch()..start();

    await _queueDao.insert(SyncQueueItemsCompanion(
      mutationId: Value(mutationId),
      tenantId: Value(tenantId),
      moduleId: Value(moduleId),
      action: Value(action),
      payloadJson: Value(jsonEncode(payload)),
      idempotencyKey: Value(mutationId),
      createdAt: Value(DateTime.now()),
    ));

    if (entityId != null) {
      await _localDataDao.updateSyncStatus(entityId, 'pending_sync');
    }

    stopwatch.stop();
    developer.log(
      'enqueue $mutationId for $moduleId/$action in ${stopwatch.elapsedMilliseconds}ms',
      name: 'Scalario.Offline.Sync',
    );

    _onEnqueuedController.add(null);

    return mutationId;
  }

  void dispose() {
    _onEnqueuedController.close();
  }
}
