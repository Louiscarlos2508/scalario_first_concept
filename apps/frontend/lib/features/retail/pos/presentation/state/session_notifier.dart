import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/retail/pos/data/models/pos_session.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/order_repository.dart';

class SessionNotifier extends StateNotifier<AsyncValue<PosSession?>> {
  final SessionRepository _repository;
  final OrderRepository _orderRepository;

  SessionNotifier(this._repository, this._orderRepository)
    : super(const AsyncValue.loading()) {
    checkActiveSession();
  }

  Future<void> checkActiveSession() async {
    state = const AsyncValue.loading();
    try {
      final session = await _repository.getActiveSession();
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
    final currentSession = state.value;
    if (currentSession == null) {
      return {};
    }

    // Local-first calculation (even offline)
    // If we have remoteId, use it, otherwise use local Id as fallback if needed
    // But sessionId in Order model is usually remote UUID or app UUID
    final sessionId = currentSession.remoteId ?? '';
    final orders = await _orderRepository.getOrdersBySession(sessionId);

    final Map<String, double> totalsByMethod = {};
    double totalSales = 0;

    for (var order in orders) {
      final method = order.paymentMethod ?? 'UNKNOWN';
      totalsByMethod[method] =
          (totalsByMethod[method] ?? 0) + order.totalAmount;
      totalSales += order.totalAmount;
    }

    return {
      'openingBalance': currentSession.openingBalance,
      'totalsByMethod': totalsByMethod,
      'totalSales': totalSales,
      'theoreticalCash':
          (currentSession.openingBalance) + (totalsByMethod['CASH'] ?? 0),
    };
  }

  Future<void> closeSession(double closingBalance) async {
    final currentSession = state.value;
    if (currentSession == null) return;

    state = const AsyncValue.loading();
    try {
      final summary = await calculateSessionSummary();
      final theoreticalBalance = summary['theoreticalCash'] as double;

      currentSession.closingBalance = closingBalance;
      currentSession.theoreticalBalance = theoreticalBalance;
      currentSession.variance = closingBalance - theoreticalBalance;
      currentSession.status = 'CLOSED';
      currentSession.closedAt = DateTime.now();

      await _repository.saveSession(currentSession);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
