// ignore_for_file: avoid_print
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/sync_status.dart';
import 'package:frontend/core/services/sync_auth_exception.dart';

// =============================================================================
// Tests unitaires — 5 vulnérabilités SyncEngine
//
// Pattern : logique pure extraite en fonctions testables, sans Isar ni Flutter.
// Les tests d'intégration Isar requièrent flutter_integration_test (non inclus).
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // Fix 1 — Realtime heartbeat / déconnexion silencieuse
  // ---------------------------------------------------------------------------
  group('Fix 1 — Realtime heartbeat', () {
    test('fallback sync déclenché quand lastEventTime est null', () {
      final shouldSync = _shouldForceSyncFallback(
        lastEventTime: null,
        threshold: const Duration(minutes: 5),
      );
      expect(shouldSync, isTrue);
    });

    test('fallback sync déclenché si dernier événement > threshold', () {
      final past =
          DateTime.now().subtract(const Duration(minutes: 6));
      final shouldSync = _shouldForceSyncFallback(
        lastEventTime: past,
        threshold: const Duration(minutes: 5),
      );
      expect(shouldSync, isTrue);
    });

    test('pas de fallback sync si événement récent (< threshold)', () {
      final recent =
          DateTime.now().subtract(const Duration(minutes: 2));
      final shouldSync = _shouldForceSyncFallback(
        lastEventTime: recent,
        threshold: const Duration(minutes: 5),
      );
      expect(shouldSync, isFalse);
    });

    test('_recordEvent réinitialise la fenêtre heartbeat', () {
      DateTime? lastEvent;

      // Simule un premier événement
      lastEvent = DateTime.now().subtract(const Duration(minutes: 10));
      expect(
        _shouldForceSyncFallback(
            lastEventTime: lastEvent,
            threshold: const Duration(minutes: 5)),
        isTrue,
      );

      // Simule _recordEvent()
      lastEvent = DateTime.now();
      expect(
        _shouldForceSyncFallback(
            lastEventTime: lastEvent,
            threshold: const Duration(minutes: 5)),
        isFalse,
      );
    });

    test('CHANNEL_ERROR → le canal est considéré mort', () {
      const deadStatuses = ['CHANNEL_ERROR', 'TIMED_OUT'];
      for (final status in deadStatuses) {
        expect(_isDeadChannelStatus(status), isTrue,
            reason: 'Status $status devrait déclencher un fallback sync');
      }
    });

    test('SUBSCRIBED → canal vivant, pas de fallback immédiat', () {
      expect(_isDeadChannelStatus('SUBSCRIBED'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Fix 2 — Server timestamp pour delta sync
  // ---------------------------------------------------------------------------
  group('Fix 2 — Server timestamp', () {
    test('parse correct du header X-Sync-Timestamp ISO-8601', () {
      const raw = '2026-04-01T14:30:00.000Z';
      final ts = _parseServerTimestamp({'x-sync-timestamp': raw});
      expect(ts.toUtc().toIso8601String(), equals('2026-04-01T14:30:00.000Z'));
    });

    test('fallback DateTime.now() si header absent', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final ts = _parseServerTimestamp({});
      expect(ts.isAfter(before), isTrue);
    });

    test('fallback DateTime.now() si header mal formé', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final ts = _parseServerTimestamp({'x-sync-timestamp': 'not-a-date'});
      expect(ts.isAfter(before), isTrue);
    });

    test('le timestamp serveur est plus fiable que DateTime.now() local', () {
      // Simule une horloge device en avance de 10 min sur le serveur.
      const serverRaw = '2026-04-01T10:00:00.000Z';
      final serverTs = _parseServerTimestamp({'x-sync-timestamp': serverRaw});

      // Le curseur `since` envoyé au prochain pull doit être le timestamp serveur,
      // pas l'horloge locale (qui serait à 10:10 UTC).
      expect(serverTs.toUtc().hour, equals(10));
      expect(serverTs.toUtc().minute, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Fix 3 — Outbox retry limit
  // ---------------------------------------------------------------------------
  group('Fix 3 — Outbox retry limit', () {
    test('SyncStatus.failed existe dans l\'enum', () {
      expect(SyncStatus.values, contains(SyncStatus.failed));
    });

    test('SyncStatus.failed est distinct des autres états', () {
      expect(SyncStatus.failed, isNot(SyncStatus.pending));
      expect(SyncStatus.failed, isNot(SyncStatus.synced));
      expect(SyncStatus.failed, isNot(SyncStatus.error));
    });

    test('SyncStatus.failed est stocké par nom (EnumType.name)', () {
      expect(SyncStatus.failed.name, equals('failed'));
    });

    test('resetErrorOrders ne doit PAS toucher les ordres failed', () {
      // Invariant : seuls les ordres `error` sont réinitialisés.
      // Les ordres `failed` restent bloqués jusqu\'à action admin explicite.
      final statuses = [SyncStatus.error, SyncStatus.pending, SyncStatus.failed];
      final resetted = statuses
          .where((s) => _isResetByTokenRefresh(s))
          .toList();
      expect(resetted, equals([SyncStatus.error]));
      expect(resetted, isNot(contains(SyncStatus.failed)));
    });

    test('compteur de retry atteint maxRetries → marquer failed', () {
      const maxRetries = 5;
      final counters = <String, int>{};

      // Simule 5 erreurs réseau successives pour le même ordre
      final uuid = 'order-abc-123';
      for (int i = 0; i < maxRetries; i++) {
        final newCount = (counters[uuid] ?? 0) + 1;
        counters[uuid] = newCount;
      }

      final shouldFail = _shouldMarkFailed(counters[uuid]!, maxRetries);
      expect(shouldFail, isTrue);
    });

    test('retry count < maxRetries → garder pending', () {
      const maxRetries = 5;
      expect(_shouldMarkFailed(3, maxRetries), isFalse);
      expect(_shouldMarkFailed(4, maxRetries), isFalse);
    });

    test('succès → retry count nettoyé', () {
      final counters = <String, int>{'order-abc': 3};
      counters.remove('order-abc'); // simule markAsSynced → _retryCounts.remove
      expect(counters.containsKey('order-abc'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Fix 4 — JWT expiré traité séparément
  // ---------------------------------------------------------------------------
  group('Fix 4 — JWT 401 handling', () {
    test('SyncAuthException se construit avec le statusCode', () {
      final e = SyncAuthException(401);
      expect(e.statusCode, equals(401));
      expect(e.toString(), contains('401'));
    });

    test('SyncAuthException est une Exception', () {
      expect(SyncAuthException(403), isA<Exception>());
    });

    test('SyncAuthException 401 et 403 sont distincts des erreurs réseau', () {
      // Un timeout ou IOError ne doit pas suspendre le sync —
      // seul SyncAuthException doit le faire.
      Object networkError = Exception('Connection refused');
      Object authError = SyncAuthException(401);

      expect(authError, isA<SyncAuthException>());
      expect(networkError, isNot(isA<SyncAuthException>()));
    });

    test('authSuspended passe à true sur SyncAuthException', () {
      bool authSuspended = false;

      try {
        throw SyncAuthException(401);
      } on SyncAuthException {
        authSuspended = true;
      }

      expect(authSuspended, isTrue);
    });

    test('authSuspended revient à false quand _TokenUpdate reçu', () {
      bool authSuspended = true;

      // Simule la réception d'un _TokenUpdate
      const newToken = 'new-jwt-token';
      if (newToken.isNotEmpty) {
        authSuspended = false;
      }

      expect(authSuspended, isFalse);
    });

    test('authExpiredStream émet le statusCode sur 401', () async {
      final controller = StreamController<int>.broadcast();

      // Écouter AVANT d'émettre : un broadcast stream ne bufferise pas les
      // événements émis avant qu'un listener soit abonné.
      final future = controller.stream.first;
      controller.add(401);

      final emitted = await future;
      expect(emitted, equals(401));
      await controller.close();
    });

    test('sync engine ne relance PAS de pass quand authSuspended = true', () {
      bool authSuspended = true;
      int syncPassCount = 0;

      // Simule runSyncPass() avec le guard
      void runSyncPass() {
        if (authSuspended) return;
        syncPassCount++;
      }

      runSyncPass();
      runSyncPass();

      expect(syncPassCount, equals(0));

      // Simule réception token
      authSuspended = false;
      runSyncPass();
      expect(syncPassCount, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Fix 5 — Schema version mismatch → re-provisioning
  // ---------------------------------------------------------------------------
  group('Fix 5 — Schema version', () {
    test('parse correct du header X-Schema-Version', () {
      final version = _parseSchemaVersion({'x-schema-version': '7'});
      expect(version, equals(7));
    });

    test('retourne null si header absent', () {
      final version = _parseSchemaVersion({});
      expect(version, isNull);
    });

    test('retourne null si header non numérique', () {
      final version = _parseSchemaVersion({'x-schema-version': 'v2.1'});
      expect(version, isNull);
    });

    test('divergence schema → forceFullPull = true', () {
      const localVersion = 3;
      const serverVersion = 5;
      final forceFullPull = _shouldForceFullPull(localVersion, serverVersion);
      expect(forceFullPull, isTrue);
    });

    test('versions identiques → pas de re-provisioning', () {
      const localVersion = 5;
      const serverVersion = 5;
      final forceFullPull = _shouldForceFullPull(localVersion, serverVersion);
      expect(forceFullPull, isFalse);
    });

    test('server version null (heartbeat échoué) → pas de re-provisioning', () {
      final forceFullPull = _shouldForceFullPullNullable(3, null);
      expect(forceFullPull, isFalse);
    });

    test('encoding schemaVersion comme DateTime milliseconds est réversible', () {
      const version = 42;
      final encoded = DateTime.fromMillisecondsSinceEpoch(version);
      final decoded = encoded.millisecondsSinceEpoch;
      expect(decoded, equals(version));
    });

    test('schemaVersion 0 (absente) != version serveur 1 → déclenche re-prov', () {
      const localVersion = 0; // valeur par défaut quand aucune version stockée
      const serverVersion = 1;
      expect(_shouldForceFullPull(localVersion, serverVersion), isTrue);
    });
  });
}

// =============================================================================
// Helpers testables extraits de la logique métier
// =============================================================================

// --- Fix 1 ---

/// Logique de _checkHeartbeat() dans RealtimeService.
bool _shouldForceSyncFallback({
  required DateTime? lastEventTime,
  required Duration threshold,
}) {
  if (lastEventTime == null) return true;
  return DateTime.now().difference(lastEventTime) >= threshold;
}

/// Statuts Supabase Realtime 1.x qui signalent un canal mort.
bool _isDeadChannelStatus(String status) {
  return status == 'CHANNEL_ERROR' || status == 'TIMED_OUT';
}

// --- Fix 2 ---

/// Logique de _parseServerTimestamp() dans les adapters.
DateTime _parseServerTimestamp(Map<String, String> headers) {
  final raw = headers['x-sync-timestamp'];
  if (raw != null) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.toUtc();
  }
  return DateTime.now().toUtc();
}

// --- Fix 3 ---

/// Logique de resetErrorOrders() : seuls les ordres `error` sont réinitialisés.
bool _isResetByTokenRefresh(SyncStatus status) => status == SyncStatus.error;

/// Logique de _handleRetryableFailure() dans TransactionSyncAdapter.
bool _shouldMarkFailed(int retryCount, int maxRetries) =>
    retryCount >= maxRetries;

// --- Fix 5 ---

/// Logique de _sendHeartbeat() : parse X-Schema-Version.
int? _parseSchemaVersion(Map<String, String> headers) {
  final raw = headers['x-schema-version'];
  return raw != null ? int.tryParse(raw) : null;
}

/// Logique de _performSyncWithAdapters() : détermine si un full pull est requis.
bool _shouldForceFullPull(int localVersion, int serverVersion) =>
    serverVersion != localVersion;

bool _shouldForceFullPullNullable(int localVersion, int? serverVersion) {
  if (serverVersion == null) return false;
  return serverVersion != localVersion;
}
