import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/features/retail/inventory/data/repositories/inventory_repository.dart';

/// Push-only sync adapter for inventory movements.
/// Reads all 'pending' [InventoryMovementLocal] records from Isar,
/// calls the corresponding API endpoint, then marks each as 'synced' or 'failed'.
class InventorySyncAdapter implements SyncAdapter {
  final InventoryRepository _repo;

  InventorySyncAdapter({required InventoryRepository repo}) : _repo = repo;

  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pending = await _repo.getPendingMovements();
    for (final movement in pending) {
      try {
        final result = await _repo.createMovement(
          type: movement.type,
          catalogItemId: movement.catalogItemId,
          quantity: movement.quantity,
          reason: movement.reason,
          referenceId: movement.referenceId,
          tenantId: movement.tenantId,
          token: token,
        );
        await _repo.markSynced(movement.id, result['id'] as String);
      } catch (e) {
        await _repo.markFailed(movement.id, e.toString());
      }
    }
  }

  /// Inventory movements are push-only (outbox pattern) — no delta pull.
  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {}
}
