import 'package:isar/isar.dart';
import 'package:frontend/core/models/sync_status.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/pos/data/models/order.dart';
import 'package:frontend/features/pos/data/models/pos_session.dart';

/// Purges old synced records from local Isar storage.
///
/// Only records with [SyncStatus.synced] are eligible for deletion.
/// Records with [SyncStatus.pending] (unsent mutations) are NEVER purged —
/// they must remain in the outbox until the server confirms receipt.
class RetentionService {
  final IsarService _isarService;

  RetentionService(this._isarService);

  /// Delete synced orders and sessions older than [retentionDays] days.
  ///
  /// Fire-and-forget: call without await on app start.
  /// Pending records are protected — only synced records are eligible.
  Future<void> purgeOldData({int retentionDays = 60}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final isar = await _isarService.db;

    // Filter synced records in Dart — createdAt/openedAt lack Isar indexes,
    // so we fetch all synced records and apply the cutoff in-memory.
    final syncedOrders = await isar.orders
        .filter()
        .syncStatusEqualTo(SyncStatus.synced)
        .findAll();
    final oldOrderIds = syncedOrders
        .where((o) => o.createdAt.isBefore(cutoff))
        .map((o) => o.id)
        .toList();

    final syncedSessions = await isar.posSessions
        .filter()
        .syncStatusEqualTo(SyncStatus.synced)
        .findAll();
    // PosSession uses openedAt (equivalent to createdAt for sessions).
    final oldSessionIds = syncedSessions
        .where((s) => s.openedAt.isBefore(cutoff))
        .map((s) => s.id)
        .toList();

    if (oldOrderIds.isEmpty && oldSessionIds.isEmpty) return;

    await isar.writeTxn(() async {
      if (oldOrderIds.isNotEmpty) {
        await isar.orders.deleteAll(oldOrderIds);
      }
      if (oldSessionIds.isNotEmpty) {
        await isar.posSessions.deleteAll(oldSessionIds);
      }
    });

    print('[RetentionService] Purged records older than $retentionDays days.');
  }
}
