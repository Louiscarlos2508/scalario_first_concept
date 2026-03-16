import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';

/// Handles order (transaction/retail sale) push to POST /retail/sales.
/// Pull is server-authoritative — orders are not pulled back to the device.
class TransactionSyncAdapter implements SyncAdapter {
  final OrderRepository _orderRepo;

  TransactionSyncAdapter({required OrderRepository orderRepo})
      : _orderRepo = orderRepo;

  /// Push pending orders to POST /retail/sales (UUID-idempotent upsert).
  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pendingOrders = await _orderRepo.getPendingOrders();
    if (pendingOrders.isEmpty) return;

    print('[TransactionAdapter] Pushing ${pendingOrders.length} pending orders');

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
          await _orderRepo.markAsSynced(order.uuid);
          print('[TransactionAdapter] Order ${order.uuid} synced');
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // 4xx = client error (auth, validation) — won't self-resolve, stop retrying.
          await _orderRepo.markAsError(order.uuid);
          print(
              '[TransactionAdapter] Order ${order.uuid} marked error (${response.statusCode}): ${response.body}');
        } else {
          // 5xx or unexpected — keep pending, will retry next cycle.
          print(
              '[TransactionAdapter] Server error for order ${order.uuid} (${response.statusCode}), will retry');
        }
      } catch (e) {
        print('[TransactionAdapter] Failed to push order ${order.uuid}: $e');
      }
    }
  }

  /// Orders are not pulled — server is authoritative for financial records.
  /// Server-wins policy: on delta pull the server version overwrites any local
  /// synced copy. Only records with syncStatus == pending are protected from
  /// overwrite (they stay in the outbox until the server confirms receipt).
  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    // Orders flow POS → server only. No delta pull needed.
  }
}
