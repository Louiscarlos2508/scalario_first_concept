import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/core/services/sync_auth_exception.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';

/// Handles POS session push to POST /pos/sessions.
/// Sessions flow POS → server only (no delta pull needed).
///
/// ## Fix 4 — JWT 401 handling
/// A 401/403 on open OR close throws [SyncAuthException] to suspend the
/// sync engine and trigger a silent token refresh before retrying.
class SessionSyncAdapter implements SyncAdapter {
  final SessionRepository _sessionRepo;

  SessionSyncAdapter({required SessionRepository sessionRepo})
      : _sessionRepo = sessionRepo;

  /// Push pending sessions.
  /// OPEN sessions  → POST /retail/sessions/open  (idempotent via uuid)
  /// CLOSED sessions → POST /retail/sessions/close/:uuid
  ///
  /// Throws [SyncAuthException] on 401/403.
  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pendingSessions = await _sessionRepo.getPendingSessions();
    if (pendingSessions.isEmpty) return;

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

        // Fix 4 — vérification 401 avant tout autre traitement.
        if (openResponse.statusCode == 401 ||
            openResponse.statusCode == 403) {
          throw SyncAuthException(openResponse.statusCode);
        }

        final openOk = openResponse.statusCode == 200 ||
            openResponse.statusCode == 201 ||
            openResponse.statusCode == 409; // already exists

        if (!openOk) {
          print('[SessionAdapter] Open failed for ${session.uuid}: '
              '${openResponse.statusCode}');
          // 400 = terminal rejection (invalid data, already in a closed state, etc.)
          // Mark as synced to stop infinite retries — data will not become valid.
          if (openResponse.statusCode == 400) {
            await _sessionRepo.markAsSynced(session.id, session.uuid);
          }
          continue;
        }

        // Step 2 — if session is CLOSED, push close as well
        if (session.status == 'CLOSED' && session.closingBalance != null) {
          final variance = session.variance ?? 0;
          final closeResponse = await http
              .post(
                Uri.parse('$baseUrl/retail/sessions/close/${session.uuid}'),
                headers: headers,
                body: jsonEncode({
                  'closingBalance': session.closingBalance,
                  if (session.theoreticalBalance != null)
                    'theoreticalBalance': session.theoreticalBalance,
                  if (session.variance != null) 'variance': session.variance,
                  // Backend requires varianceExplanation when variance != 0.
                  // Use the explanation saved at close time; fall back to a
                  // generic string only if none was recorded (should not happen).
                  if (variance != 0)
                    'varianceExplanation': session.varianceExplanation?.isNotEmpty == true
                        ? session.varianceExplanation!
                        : 'Écart constaté en fermeture',
                }),
              )
              .timeout(const Duration(seconds: 10));

          // Fix 4 — 401 sur le close = même traitement.
          if (closeResponse.statusCode == 401 ||
              closeResponse.statusCode == 403) {
            throw SyncAuthException(closeResponse.statusCode);
          }

          if (closeResponse.statusCode == 200 ||
              closeResponse.statusCode == 201) {
            await _sessionRepo.markAsSynced(session.id, session.uuid);
          } else {
            print('[SessionAdapter] Close failed for ${session.uuid}: '
                '${closeResponse.statusCode}');
          }
        } else {
          await _sessionRepo.markAsSynced(session.id, session.uuid);
        }
      } catch (e) {
        if (e is SyncAuthException) rethrow;
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
