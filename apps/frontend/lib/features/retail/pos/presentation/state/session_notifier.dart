import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';
import 'package:frontend/core/models/sync_status.dart';

class SessionNotifier extends StateNotifier<AsyncValue<PosSession?>> {
  final SessionRepository _repository;
  final OrderRepository _orderRepository;
  final String _userId;

  SessionNotifier(this._repository, this._orderRepository, {required String userId})
    : _userId = userId,
      super(const AsyncValue.loading()) {
    checkActiveSession();
  }

  Future<void> checkActiveSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.getActiveSession(userId: _userId);
      state = AsyncValue.data(session);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> openSession(PosSession session) async {
    state = const AsyncValue.loading();
    try {
      await _repository.saveSession(session);
      state = AsyncValue.data(session);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Map<String, dynamic>> calculateSessionSummary() async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) {
      return {};
    }

    // Local-first calculation (even offline)
    // If we have remoteId, use it, otherwise use local Id as fallback if needed
    // But sessionId in Order model is usually remote UUID or app UUID
    final sessionId = currentSession.remoteId;
    final orders = await _orderRepository.getOrdersBySession(sessionId);

    final Map<String, double> totalsByMethod = {};
    double totalSales = 0;
    int orderCount = 0;
    int splitCount = 0;

    for (var order in orders) {
      totalSales += order.totalAmount;
      orderCount++;

      final splitsJson = order.paymentSplits;
      if (splitsJson != null && splitsJson.isNotEmpty) {
        // Vente split — ventiler chaque part dans sa méthode
        splitCount++;
        try {
          final splits = jsonDecode(splitsJson) as Map<String, dynamic>;
          for (final entry in splits.entries) {
            final method = entry.key;
            final amount = (entry.value as num).toDouble();
            totalsByMethod[method] = (totalsByMethod[method] ?? 0) + amount;
          }
        } catch (_) {
          // JSON malformé — fallback sur le total brut sous SPLIT
          totalsByMethod['SPLIT'] =
              (totalsByMethod['SPLIT'] ?? 0) + order.totalAmount;
        }
      } else {
        final method = order.paymentMethod ?? 'CASH';
        totalsByMethod[method] =
            (totalsByMethod[method] ?? 0) + order.totalAmount;
      }
    }

    return {
      'openingBalance': currentSession.openingBalance,
      'totalsByMethod': totalsByMethod,
      'totalSales': totalSales,
      'orderCount': orderCount,
      'splitCount': splitCount,
      'theoreticalCash':
          (currentSession.openingBalance) + (totalsByMethod['CASH'] ?? 0),
    };
  }

  Future<void> closeSession(double closingBalance, double theoreticalBalance) async {
    final currentSession = state.valueOrNull;
    if (currentSession == null) return;

    state = const AsyncValue.loading();
    try {
      currentSession.closingBalance = closingBalance;
      currentSession.theoreticalBalance = theoreticalBalance;
      currentSession.variance = closingBalance - theoreticalBalance;
      currentSession.status = 'CLOSED';
      currentSession.closedAt = DateTime.now();
      currentSession.syncStatus = SyncStatus.pending; // re-sync to push CLOSED status

      await _repository.saveSession(currentSession);
      // Keep closed session in state so SessionGuard can show the "closed" screen.
      state = AsyncValue.data(currentSession);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Called when the user taps "Ouvrir nouvelle session" from the closed screen.
  void resetForNewSession() {
    state = const AsyncValue.data(null);
  }
}
