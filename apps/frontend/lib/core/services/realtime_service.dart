import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/services/sync_service.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';

/// Gère les abonnements Supabase Realtime et la détection de déconnexion silencieuse.
///
/// ## Fix 1 — Realtime WebSocket silencieux
/// - Callback statut `SUBSCRIBED` / `CHANNEL_ERROR` / `TIMED_OUT` → fallback sync.
/// - Heartbeat périodique : si aucun événement depuis [_kFallbackThreshold] → `forceSync()`.
///
/// ## Scale — Tenant filter (anti-thundering-herd)
///
/// **Problème** : sans filtre, chaque device reçoit les événements Postgres de
/// TOUS les tenants. À 10 000 boutiques, le canal `public:products` déverse des
/// notifications pour des boutiques étrangères → surcharge client + syncs inutiles.
///
/// **Solution** : `ChannelFilter(filter: 'tenant_id=eq.$tenantId')` limite les
/// notifications au tenant courant côté serveur Supabase.
///
/// ## Scale — Jitter sur le heartbeat et les reconnexions
///
/// **Problème** : `Timer.periodic` démarrant à T+0 pour tous les devices qui
/// redémarrent simultanément (après un déploiement ou une panne Supabase) crée
/// une vague synchronisée toutes les [_kHeartbeatInterval].
///
/// **Solution** :
/// - Heartbeat démarre après un délai aléatoire [_kJitterMaxSeconds] (0–60 s).
/// - Reconnexion après `SUBSCRIBED` : délai aléatoire 0–30 s avant `forceSync()`.
class RealtimeService {
  final SupabaseClient _supabase;
  final SyncService _syncService;
  final Ref _ref;

  /// Filtre tenant pour les channels Realtime.
  /// Null = pas de filtre (non connecté). Init() refuse de s'exécuter si null.
  final String? tenantId;

  bool _isInitialized = false;
  DateTime? _lastEventTime;
  Timer? _heartbeatTimer;

  static const _kHeartbeatInterval = Duration(minutes: 5);
  static const _kFallbackThreshold = Duration(minutes: 5);

  /// Jitter max au démarrage du heartbeat (disperser la vague post-déploiement).
  static const _kJitterMaxSeconds = 60;

  /// Jitter max sur les reconnexions `SUBSCRIBED` (disperser le thundering herd).
  static const _kReconnectJitterMaxSeconds = 30;

  // Statuts supabase_flutter 1.x
  static const _kSubscribed = 'SUBSCRIBED';
  static const _kChannelError = 'CHANNEL_ERROR';
  static const _kTimedOut = 'TIMED_OUT';

  RealtimeService(this._supabase, this._syncService, this._ref,
      {this.tenantId});

  void init() {
    if (_isInitialized) return;
    // Ne pas s'abonner sans tenantId — évite les channels sans filtre
    // qui écouteraient l'intégralité de la table.
    if (tenantId == null) return;

    _subscribeProducts();
    _subscribeStockMovements();
    _subscribeOrders();
    _startHeartbeat();

    _isInitialized = true;
    print('[RealtimeService] tenant=$tenantId — subscriptions active, '
        'heartbeat jitter=${_kJitterMaxSeconds}s.');
  }

  // ---------------------------------------------------------------------------
  // Abonnements avec filtre tenant (Scale fix)
  // ---------------------------------------------------------------------------

  void _subscribeProducts() {
    _supabase
        .channel('pos:products:$tenantId')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: '*',
            schema: 'public',
            table: 'products',
            // Filtre côté serveur — seuls les events du tenant courant arrivent.
            filter: 'tenant_id=eq.$tenantId',
          ),
          (payload, [ref]) {
            print('[Realtime] Product change (tenant=$tenantId)');
            _recordEvent();
            _syncService.forceSync();
          },
        )
        .subscribe(_statusCallback('products'));
  }

  void _subscribeStockMovements() {
    _supabase
        .channel('pos:stock_movements:$tenantId')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'stock_movements',
            filter: 'tenant_id=eq.$tenantId',
          ),
          (payload, [ref]) {
            print('[Realtime] Stock movement (tenant=$tenantId)');
            _recordEvent();
            _syncService.forceSync();
          },
        )
        .subscribe(_statusCallback('stock_movements'));
  }

  void _subscribeOrders() {
    _supabase
        .channel('pos:orders:$tenantId')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'orders',
            filter: 'tenant_id=eq.$tenantId',
          ),
          (payload, [ref]) {
            print('[Realtime] New order (tenant=$tenantId) — refreshing dashboard');
            _recordEvent();
            _ref.invalidate(salesStatsProvider);
            _ref.invalidate(salesReportProvider);
          },
        )
        .subscribe(_statusCallback('orders'));
  }

  // ---------------------------------------------------------------------------
  // Callback statut — supabase_flutter 1.x : void Function(String, [Object?])
  // ---------------------------------------------------------------------------

  void Function(String, [Object?]) _statusCallback(String channelName) {
    return (status, [error]) {
      if (status == _kSubscribed) {
        print('[RealtimeService] [$channelName] SUBSCRIBED (tenant=$tenantId)');
        _recordEvent();
        // Scale fix: jitter 0–30s pour disperser la vague post-reconnexion.
        final jitter = Duration(seconds: Random().nextInt(_kReconnectJitterMaxSeconds));
        Timer(jitter, () => _syncService.forceSync());
      } else if (status == _kChannelError) {
        print('[RealtimeService] [$channelName] CHANNEL_ERROR: $error — fallback sync');
        _syncService.forceSync();
      } else if (status == _kTimedOut) {
        print('[RealtimeService] [$channelName] TIMED_OUT — fallback sync');
        _syncService.forceSync();
      }
    };
  }

  // ---------------------------------------------------------------------------
  // Heartbeat avec jitter au démarrage (Scale fix)
  // ---------------------------------------------------------------------------

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();

    // Délai de départ aléatoire pour éviter que tous les devices qui démarrent
    // simultanément (post-déploiement, panne Supabase) ne synchronisent leurs
    // Timer.periodic et provoquent une vague toutes les 5 min à l'heure pile.
    final startJitter =
        Duration(seconds: Random().nextInt(_kJitterMaxSeconds));

    Timer(startJitter, () {
      _checkHeartbeat();
      _heartbeatTimer = Timer.periodic(_kHeartbeatInterval, (_) {
        _checkHeartbeat();
      });
    });
  }

  void _checkHeartbeat() {
    final last = _lastEventTime;
    final now = DateTime.now();
    if (last == null || now.difference(last) >= _kFallbackThreshold) {
      print('[RealtimeService] Heartbeat: no event >= ${_kFallbackThreshold.inMinutes}min'
          ' (tenant=$tenantId) — forcing delta pull');
      _syncService.forceSync();
    }
  }

  void _recordEvent() => _lastEventTime = DateTime.now();

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isInitialized = false;
  }
}
