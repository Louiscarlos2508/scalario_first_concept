import 'package:isar/isar.dart';

part 'inventory_movement_local.g.dart';

/// Local outbox model for inventory movements (offline-first).
/// Persisted in Isar until successfully synced to the server.
@collection
class InventoryMovementLocal {
  Id id = Isar.autoIncrement;

  /// Remote ID assigned by the server after successful sync.
  String? remoteId;

  /// Movement type: DELIVERY, TRANSFER_OUT, TRANSFER_IN, LOSS, ADJUSTMENT
  @Index()
  late String type;

  late String catalogItemId;
  late int quantity;
  String? reason;

  /// Used for TRANSFER_OUT / TRANSFER_IN chain-of-custody.
  String? referenceId;

  late String tenantId;
  late DateTime createdAt;

  /// Sync lifecycle: 'pending' | 'synced' | 'failed'
  @Index()
  late String syncStatus;

  /// Error message when syncStatus == 'failed'.
  String? errorMessage;
}
