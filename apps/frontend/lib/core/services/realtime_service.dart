import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';

/// Service de synchronisation périodique (polling + connectivity-triggered).
///
/// ## Pourquoi pas de Supabase Realtime Channels ?
///
/// `supabase_flutter 1.x` / `realtime_client 1.4.0` contient un bug non corrigé :
/// le `RetryTimer` interne et le `sendHeartbeat` interne à `RealtimeClient`
/// continuent d'écrire sur un `WebSocketSink` déjà fermé même après
/// `removeChannel()`, causant un crash non catchable :
///   "Bad state: Cannot add event after closing"
///
/// Ce bug est corrigé dans `realtime_client 2.x` (= `supabase_flutter 2.x`).
/// Migration prévue quand le projet monte de version.
///
/// ## Architecture actuelle (polling)
///
/// Le sync est déclenché par :
/// 1. **Heartbeat periodique** (toutes les [_kHeartbeatInterval] + jitter)
///    — garantit qu'aucune mise à jour ne dépasse [_kHeartbeatInterval] de retard.
/// 2. **`SyncService._connectivitySubscription`** — déclenche un `forceSync()`
///    immédiat au retour réseau (câblé dans `sync_service.dart`).
/// 3. **Dashboard invalidation** — déclenché manuellement si nécessaire.
///
/// Pour un POS en production, un délai max de 5 min sur les mises à jour
/// catalogue est largement acceptable. Les commandes (outbox) elles sont
/// envoyées au prochain pass sync (30s–5min selon les retries).
class RealtimeService {
  // SupabaseClient conservé pour compatibilité future (migration 2.x).
  // ignore: unused_field
  final SupabaseClient _supabase;
  final SyncService _syncService;
  final Ref _ref;
  final String? tenantId;

  bool _isInitialized = false;
  Timer? _heartbeatTimer;
  Timer? _jitterStartTimer;

  /// Intervalle entre deux syncs forcés (baseline).
  static const _kHeartbeatInterval = Duration(minutes: 5);

  /// Jitter max au démarrage — disperser la vague post-déploiement/reboot.
  static const _kJitterMaxSeconds = 60;

  RealtimeService(this._supabase, this._syncService, this._ref,
      {this.tenantId});

  void init() {
    if (_isInitialized) return;
    if (tenantId == null) return;

    _startHeartbeat();
    _isInitialized = true;

    print('[RealtimeService] tenant=$tenantId — polling heartbeat started '
        '(interval=${_kHeartbeatInterval.inMinutes}min, '
        'jitter=${_kJitterMaxSeconds}s). '
        'Note: Supabase Realtime channels désactivés (bug realtime_client 1.4.0 — '
        'activer après migration supabase_flutter 2.x).');
  }

  // ---------------------------------------------------------------------------
  // Heartbeat périodique avec jitter (anti-thundering-herd)
  // ---------------------------------------------------------------------------

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _jitterStartTimer?.cancel();

    // Délai aléatoire au démarrage pour que les N caisses qui s'allument
    // au même moment (8h00 lundi) ne synchronisent pas leurs timers.
    final startJitter =
        Duration(seconds: Random().nextInt(_kJitterMaxSeconds));

    _jitterStartTimer = Timer(startJitter, () {
      if (!_isInitialized) return;
      _syncService.forceSync();
      _heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) {
        if (_isInitialized) _syncService.forceSync();
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Dashboard invalidation (à appeler depuis les écrans si nécessaire)
  // ---------------------------------------------------------------------------

  /// Invalide les providers de reporting sans passer par Realtime.
  /// Appeler après qu'une action locale sache qu'un rafraîchissement est utile.
  void invalidateDashboard() {
    if (!_isInitialized) return;
    _ref.invalidate(salesStatsProvider);
    _ref.invalidate(salesReportProvider);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    _isInitialized = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _jitterStartTimer?.cancel();
    _jitterStartTimer = null;
    print('[RealtimeService] Disposed (tenant=$tenantId).');
  }
}
