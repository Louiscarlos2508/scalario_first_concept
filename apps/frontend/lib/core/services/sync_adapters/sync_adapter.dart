/// Module-agnostic interface for entity-specific sync logic.
/// Each adapter handles push (outbox → server) and pull (server → local) for one entity type.
abstract class SyncAdapter {
  /// Push all locally pending records to the server.
  Future<void> pushPending(String baseUrl, String tenantId);

  /// Pull delta records from the server (records updated since [since]).
  /// If [since] is null, performs a full pull.
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since);
}
