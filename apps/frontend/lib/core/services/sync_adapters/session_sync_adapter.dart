import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';

/// Handles POS session push to POST /pos/sessions.
/// Sessions flow POS → server only (no delta pull needed).
class SessionSyncAdapter implements SyncAdapter {
  final SessionRepository _sessionRepo;

  SessionSyncAdapter({required SessionRepository sessionRepo})
      : _sessionRepo = sessionRepo;

  /// Push pending sessions.
  /// OPEN sessions  → POST /retail/sessions/open  (idempotent via uuid)
  /// CLOSED sessions → POST /retail/sessions/close/:uuid
  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pendingSessions = await _sessionRepo.getPendingSessions();
    if (pendingSessions.isEmpty) return;

    print('[SessionAdapter] Pushing ${pendingSessions.length} pending sessions');

    final headers = {
      'Content-Type': 'application/json',
      'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    for (final session in pendingSessions) {
      if (session.uuid.isEmpty ||
          session.userId.isEmpty ||
          session.tenantId.isEmpty) {
        continue;
      }

      try {
        // Step 1 — ensure session is opened on server (idempotent)
        final openResponse = await http
            .post(
              Uri.parse('$baseUrl/retail/sessions/open'),
              headers: headers,
              body: jsonEncode({
                'userId': session.userId,
                'tenantId': session.tenantId,
                'openingBalance': session.openingBalance,
                'deviceId': session.deviceId,
                'uuid': session.uuid,
              }),
            )
            .timeout(const Duration(seconds: 10));

        final openOk = openResponse.statusCode == 200 ||
            openResponse.statusCode == 201 ||
            openResponse.statusCode == 409; // already exists

        if (!openOk) {
          print('[SessionAdapter] Open failed for ${session.uuid}: ${openResponse.statusCode}');
          continue;
        }

        // Step 2 — if session is CLOSED, push close as well
        if (session.status == 'CLOSED' && session.closingBalance != null) {
          final closeResponse = await http
              .post(
                Uri.parse('$baseUrl/retail/sessions/close/${session.uuid}'),
                headers: headers,
                body: jsonEncode({
                  'closingBalance': session.closingBalance,
                  if (session.theoreticalBalance != null)
                    'theoreticalBalance': session.theoreticalBalance,
                  if (session.variance != null) 'variance': session.variance,
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (closeResponse.statusCode == 200 ||
              closeResponse.statusCode == 201) {
            await _sessionRepo.markAsSynced(session.id, session.uuid);
            print('[SessionAdapter] Session ${session.uuid} closed & synced');
          } else {
            print('[SessionAdapter] Close failed for ${session.uuid}: ${closeResponse.statusCode}');
          }
        } else {
          await _sessionRepo.markAsSynced(session.id, session.uuid);
          print('[SessionAdapter] Session ${session.uuid} opened & synced');
        }
      } catch (e) {
        print('[SessionAdapter] Failed to push session ${session.uuid}: $e');
      }
    }
  }

  /// Sessions are not pulled — device owns its own session state.
  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    // Sessions flow POS → server only. No delta pull needed.
  }
}
