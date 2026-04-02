import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/core/services/sync_auth_exception.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';

/// Handles order (transaction/retail sale) push to POST /retail/sales.
/// Pull is server-authoritative — orders are not pulled back to the device.
///
/// ## Fix 3 — Outbox retry limit (persistant)
/// Le compteur de retry est stocké dans le champ [Order.retryCount] en Isar.
/// Il survit aux redémarrages de l'app (contrairement au Map in-memory précédent).
/// Après [_maxRetries] échecs consécutifs réseau/5xx, l'ordre est marqué
/// [SyncStatus.failed] et exclus de l'outbox — action admin requise pour retenter.
///
/// ## Fix 4 — JWT 401 handling
/// Lève [SyncAuthException] sur 401/403. Le sync engine suspend le timer
/// et déclenche un silent token refresh.
class TransactionSyncAdapter implements SyncAdapter {
  final OrderRepository _orderRepo;
  static const int _maxRetries = 5;

  TransactionSyncAdapter({required OrderRepository orderRepo})
      : _orderRepo = orderRepo;

  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pendingOrders = await _orderRepo.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    for (final order in pendingOrders) {
      if (order.uuid.isEmpty ||
          order.sessionId == null ||
          order.sessionId!.isEmpty) {
        continue;
      }

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/retail/sales'),
              headers: {
                'Content-Type': 'application/json',
                'x-tenant-id': tenantId,
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'transactionId': order.uuid,
                'totalAmount': order.totalAmount,
                'items': order.items.map((i) => i.toJson()).toList(),
                'sessionId': order.sessionId,
                'paymentMethod': order.paymentMethod,
                'paymentSplits': order.paymentSplits,
                'customerId': order.customerId,
                'tenantId': order.tenantId ?? tenantId,
                'createdAt': order.createdAt.toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await _orderRepo.resetRetryCount(order.uuid);
          await _orderRepo.markAsSynced(order.uuid);
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          // Fix 4 — suspend le sync engine, attend le refresh token.
          throw SyncAuthException(response.statusCode);
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // 4xx permanent — données invalides, ne pas retenter.
          await _orderRepo.resetRetryCount(order.uuid);
          await _orderRepo.markAsError(order.uuid);
          print('[TransactionAdapter] Order ${order.uuid} marked error '
              '(${response.statusCode}): ${response.body}');
        } else {
          // 5xx — incrémenter le compteur persistant (Fix 3).
          await _handleRetryableFailure(
            order.uuid,
            'HTTP ${response.statusCode}: ${response.body}',
          );
        }
      } catch (e) {
        if (e is SyncAuthException) rethrow;
        // Erreur réseau — incrémenter le compteur persistant (Fix 3).
        await _handleRetryableFailure(order.uuid, e.toString());
      }
    }
  }

  /// Incrémente [Order.retryCount] en Isar. Après [_maxRetries], marque l'ordre
  /// en `failed` et loggue le payload pour diagnostic admin.
  Future<void> _handleRetryableFailure(String uuid, String error) async {
    final newCount = await _orderRepo.incrementRetryCount(uuid);

    if (newCount >= _maxRetries) {
      await _orderRepo.markAsFailed(uuid);
      print('[TransactionAdapter] PERMANENT FAILURE order=$uuid '
          'after $_maxRetries retries. last_error=$error');
    } else {
      print('[TransactionAdapter] Retry $newCount/$_maxRetries '
          'order=$uuid error=$error');
    }
  }

  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    // Orders flow POS → server only. No delta pull needed.
  }
}
