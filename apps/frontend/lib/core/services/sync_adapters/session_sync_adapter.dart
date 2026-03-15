import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/features/pos/data/repositories/session_repository.dart';

/// Handles POS session push to POST /pos/sessions.
/// Sessions flow POS → server only (no delta pull needed).
class SessionSyncAdapter implements SyncAdapter {
  final SessionRepository _sessionRepo;

  SessionSyncAdapter({required SessionRepository sessionRepo})
      : _sessionRepo = sessionRepo;

  /// Push pending sessions (UUID-idempotent upsert).
  @override
  Future<void> pushPending(String baseUrl, String tenantId) async {
    final pendingSessions = await _sessionRepo.getPendingSessions();
    if (pendingSessions.isEmpty) return;

    print('[SessionAdapter] Pushing ${pendingSessions.length} pending sessions');

    for (final session in pendingSessions) {
      if (session.uuid.isEmpty ||
          session.userId.isEmpty ||
          session.tenantId.isEmpty) {
        continue;
      }

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/pos/sessions'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(session.toJson()),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          await _sessionRepo.markAsSynced(
              session.id, data['id'] ?? session.uuid);
          print('[SessionAdapter] Session ${session.uuid} synced');
        }
      } catch (e) {
        print('[SessionAdapter] Failed to push session ${session.uuid}: $e');
      }
    }
  }

  /// Sessions are not pulled — device owns its own session state.
  @override
  Future<void> pullDelta(
      String baseUrl, String tenantId, DateTime? since) async {
    // Sessions flow POS → server only. No delta pull needed.
  }
}
