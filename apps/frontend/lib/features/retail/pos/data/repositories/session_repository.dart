import 'package:isar/isar.dart';
import 'package:frontend/core/models/sync_status.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:uuid/uuid.dart';

class SessionRepository {
  final IsarService _isarService;

  SessionRepository(this._isarService);

  Future<PosSession?> getActiveSession({required String userId}) async {
    final isar = await _isarService.db;
    return await isar.posSessions
        .filter()
        .userIdEqualTo(userId)
        .and()
        .statusEqualTo('OPEN')
        .findFirst();
  }

  final Uuid _uuid = const Uuid();

  Future<void> saveSession(PosSession session) async {
    final isar = await _isarService.db;
    if (session.uuid.isEmpty) {
      session.uuid = _uuid.v4();
    }
    await isar.writeTxn(() async {
      await isar.posSessions.put(session);
    });
  }

  Future<void> clearSessions() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.posSessions.clear();
    });
  }

  Future<List<PosSession>> getPendingSessions() async {
    final isar = await _isarService.db;
    return await isar.posSessions
        .filter()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
  }

  Future<void> markAsSynced(int localId, String uuid) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final session = await isar.posSessions.get(localId);
      if (session != null) {
        session.syncStatus = SyncStatus.synced;
        session.uuid = uuid;
        await isar.posSessions.put(session);
      }
    });
  }

  // --- Sync Metadata Helpers ---
  Future<DateTime?> getLastSync(String key) => _isarService.getLastSync(key);
  Future<void> updateLastSync(String key, DateTime timestamp) =>
      _isarService.updateLastSync(key, timestamp);

  // --- Fix 5: Schema Version ---
  Future<int> getSchemaVersion() => _isarService.getSchemaVersion();
  Future<void> updateSchemaVersion(int version) =>
      _isarService.updateSchemaVersion(version);
}
