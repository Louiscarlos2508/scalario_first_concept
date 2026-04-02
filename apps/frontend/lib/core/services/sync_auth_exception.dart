/// Thrown by SyncAdapters when the server returns HTTP 401 or 403.
///
/// Distinct from a generic network [Exception] so the SyncEngine can:
///   1. Stop the current sync pass immediately (no partial retries).
///   2. Send an [_AuthExpiredEvent] to the main isolate.
///   3. Suspend the retry timer until a [_TokenUpdate] arrives.
class SyncAuthException implements Exception {
  final int statusCode;
  SyncAuthException(this.statusCode);

  @override
  String toString() =>
      'SyncAuthException: HTTP $statusCode — JWT expired or unauthorized';
}
