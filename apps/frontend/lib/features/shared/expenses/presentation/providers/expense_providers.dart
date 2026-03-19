import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/expenses/data/models/expense.dart';
import 'package:frontend/features/shared/expenses/data/repositories/expense_repository.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:http/http.dart' as http;

/// Repository provider — injectable for tests.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// Override in tests with a mock HTTP client.
final expenseHttpClientProvider = Provider<http.Client>((ref) => http.Client());

/// Lists expenses for the active tenant, filtered by the shared date range.
/// Watches [salesStatsDateRangeProvider] so it stays in sync with other KPIs.
final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];

  final range = ref.watch(salesStatsDateRangeProvider);
  final repo = ref.watch(expenseRepositoryProvider);

  final now = DateTime.now();
  final effectiveRange = range ??
      DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);

  return repo.list(
    tenantId: tenantId,
    from: effectiveRange.start,
    to: effectiveRange.end,
  );
});
