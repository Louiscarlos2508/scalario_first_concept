import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';

import '../dao/sync_queue_dao.dart';
import 'connectivity_listener.dart';
import 'retry_policy.dart';
import 'sync_api_client.dart' show SyncApiClient, SyncApiError, SyncMutationPayload;

class SyncQueueWorker {
  SyncQueueWorker({
    required SyncQueueDao queueDao,
    required SyncApiClient apiClient,
    required ConnectivityListener connectivityListener,
    required String tenantSlug,
    RetryPolicy? retryPolicy,
    Duration drainCooldown = const Duration(seconds: 2),
    this.maxRetries = 10,
    Stream<void>? enqueueStream,
  })  : _queueDao = queueDao,
        _apiClient = apiClient,
        _connectivityListener = connectivityListener,
        _tenantSlug = tenantSlug,
        _retryPolicy = retryPolicy ?? RetryPolicy(),
        _drainCooldown = drainCooldown,
        _enqueueStream = enqueueStream;

  final SyncQueueDao _queueDao;
  final SyncApiClient _apiClient;
  final ConnectivityListener _connectivityListener;
  final String _tenantSlug;
  final RetryPolicy _retryPolicy;
  final Duration _drainCooldown;
  final int maxRetries;
  final Stream<void>? _enqueueStream;
  StreamSubscription<void>? _enqueueSubscription;

  bool _isDraining = false;
  bool _isActive = true;

  Future<void> start() async {
    _connectivityListener.listen(_onConnectivityChanged);
    _enqueueSubscription = _enqueueStream?.listen((_) => triggerDrain());

    await _queueDao.recoverInFlight(tenantId: _tenantSlug);

    unawaited(_drain());
  }

  void _onConnectivityChanged(ConnectivityResult status) {
    if (status != ConnectivityResult.none) {
      developer.log(
        'Connectivity restored: $status — triggering drain',
        name: 'Scalario.Offline.Sync',
      );
      unawaited(_drain());
    } else {
      developer.log(
        'Connectivity lost — pausing drain',
        name: 'Scalario.Offline.Sync',
        level: 800,
      );
    }
  }

  void triggerDrain() {
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_isDraining || !_isActive) return;
    _isDraining = true;

    try {
      while (_isActive) {
        final batch = await _queueDao.fetchEligible(
          tenantId: _tenantSlug,
          now: DateTime.now(),
        );

        if (batch.isEmpty) break;

        final mutationIds = batch.map((m) => m.mutationId).toList();
        await _queueDao.markSending(mutationIds);

        try {
          final response = await _apiClient.postMutations(
            tenantSlug: _tenantSlug,
            mutations: batch
                .map((m) => SyncMutationPayload(
                      mutationId: m.mutationId,
                      moduleId: m.moduleId,
                      action: m.action,
                      payload: m.payloadJson.isNotEmpty
                          ? _tryJsonDecode(m.payloadJson)
                          : {},
                    ))
                .toList(),
          );

          for (final item in response.results) {
            switch (item.status) {
              case 'success':
                await _queueDao.markSuccess(item.mutationId);
                developer.log(
                  'Mutation $item.mutationId → success',
                  name: 'Scalario.Offline.Sync',
                );
              case 'conflict':
                await _queueDao.markConflict(
                  item.mutationId,
                  error: item.error,
                );
                developer.log(
                  'Mutation $item.mutationId → conflict',
                  name: 'Scalario.Offline.Sync',
                  level: 800,
                );
              case 'error':
                await _queueDao.markPermanentError(
                  item.mutationId,
                  error: item.error ?? 'Unknown server error',
                );
                developer.log(
                  'Mutation $item.mutationId → permanent error: ${item.error}',
                  name: 'Scalario.Offline.Sync',
                  level: 900,
                );
              default:
                await _queueDao.markPermanentError(
                  item.mutationId,
                  error: 'Unknown status: ${item.status}',
                );
            }
          }
        } catch (e) {
          final isSyncApiError = e is SyncApiError;
          final isRetryable = !isSyncApiError || e.isRetryable;
          final statusCode = isSyncApiError ? e.statusCode : null;

          final now = DateTime.now();

          for (final m in batch) {
            final canRetry = isRetryable &&
                (m.retryCount + 1) < maxRetries;

            if (canRetry) {
              final nextRetry = now.add(
                _retryPolicy.nextBackoff(m.retryCount + 1),
              );
              await _queueDao.markErrorWithBackoff(
                mutationId: m.mutationId,
                error: e.toString(),
                nextRetryAt: nextRetry,
              );
            } else if (statusCode == 409) {
              await _queueDao.markConflict(
                m.mutationId,
                error: e.toString(),
              );
            } else {
              await _queueDao.markPermanentError(
                m.mutationId,
                error: e.toString(),
              );
            }
          }

          developer.log(
            'Batch drain failed (${batch.length} mutations): $e',
            name: 'Scalario.Offline.Sync',
            level: 900,
          );

          if (isRetryable) {
            break;
          }
        }

        await Future<void>.delayed(_drainCooldown);
      }
    } finally {
      _isDraining = false;
    }
  }

  void pause() {
    _isActive = false;
  }

  void resume() {
    if (!_isActive) {
      _isActive = true;
      unawaited(_drain());
    }
  }

  void dispose() {
    _isActive = false;
    _enqueueSubscription?.cancel();
    _connectivityListener.dispose();
    _apiClient.dispose();
  }
}

Map<String, dynamic> _tryJsonDecode(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) return decoded;
    developer.log(
      'Payload is not a JSON object, sending empty map',
      name: 'Scalario.Offline.Sync',
      level: 800,
    );
    return <String, dynamic>{};
  } catch (e) {
    developer.log(
      'Failed to decode payload JSON: $e',
      name: 'Scalario.Offline.Sync',
      level: 900,
    );
    return <String, dynamic>{};
  }
}
