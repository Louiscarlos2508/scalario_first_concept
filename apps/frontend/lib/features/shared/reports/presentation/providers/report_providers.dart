import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/shared/reports/data/models/sales_stat.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/retail/pos/presentation/providers/pos_providers.dart';

Map<String, String> _authHeaders({String? tenantId}) {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  return {
    'Content-Type': 'application/json',
    if (tenantId != null) 'x-tenant-id': tenantId,
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

/// Set to true to programmatically open SessionHistoryScreen inside ReportsScreen.
final showSessionHistoryProvider = StateProvider<bool>((ref) => false);

final salesStatsDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

final salesStatsProvider = FutureProvider<List<SalesStat>>((ref) async {
  final range = ref.watch(salesStatsDateRangeProvider);
  final tenantId = ref.watch(activeTenantProvider);

  // Default to last 7 days so the "7 derniers jours" label matches the data.
  final now = DateTime.now();
  final effectiveRange =
      range ??
      DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);

  String url = '${ApiConstants.baseUrl}/reports/sales/stats';
  final queryParams = <String, String>{
    'from': DateFormat('yyyy-MM-dd').format(effectiveRange.start),
    'to': DateFormat('yyyy-MM-dd').format(effectiveRange.end),
  };

  if (tenantId != null) {
    queryParams['tenantId'] = tenantId;
  }

  final uri = Uri.parse(url).replace(queryParameters: queryParams);
  final response = await http.get(
    uri,
    headers: _authHeaders(tenantId: tenantId),
  );

  if (response.statusCode == 200) {
    final dynamic decoded = jsonDecode(response.body);
    List<SalesStat> rawStats;
    if (decoded is Map<String, dynamic>) {
      // Backend returns aggregate + dailyStats array.
      // Use dailyStats when available so the chart shows real per-day values.
      final dailyList = decoded['dailyStats'] as List<dynamic>?;
      if (dailyList != null && dailyList.isNotEmpty) {
        rawStats = dailyList
            .map((json) => SalesStat.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Fallback: no daily breakdown yet — put the aggregate total on today.
        rawStats = [
          SalesStat(
            day: DateTime.now(),
            revenue: (decoded['totalRevenue'] as num?)?.toDouble() ?? 0,
            orderCount: (decoded['saleCount'] as num?)?.toInt() ?? 0,
          ),
        ];
      }
    } else {
      rawStats = (decoded as List<dynamic>)
          .map((json) => SalesStat.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    // Always return exactly 7 daily points so the chart has a connected line.
    final end = DateTime(
      effectiveRange.end.year,
      effectiveRange.end.month,
      effectiveRange.end.day,
    );
    final allDays = List.generate(7, (i) => end.subtract(Duration(days: 6 - i)));
    return allDays.map((day) {
      return rawStats.firstWhere(
        (s) =>
            s.day.year == day.year &&
            s.day.month == day.month &&
            s.day.day == day.day,
        orElse: () => SalesStat(day: day, revenue: 0, orderCount: 0),
      );
    }).toList();
  } else {
    throw Exception('Failed to fetch sales stats: ${response.statusCode}');
  }
});

final salesReportDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

final salesReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final range = ref.watch(salesReportDateRangeProvider);
  final tenantId = ref.watch(activeTenantProvider);

  String url = '${ApiConstants.baseUrl}/reports/sales';
  final queryParams = <String, String>{};

  if (range != null) {
    queryParams['start'] = DateFormat('yyyy-MM-dd').format(range.start);
    queryParams['end'] = DateFormat('yyyy-MM-dd').format(range.end);
  }

  if (tenantId != null) {
    queryParams['tenantId'] = tenantId;
  }

  final uri = Uri.parse(url).replace(queryParameters: queryParams);
  final response = await http.get(
    uri,
    headers: _authHeaders(tenantId: tenantId),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch sales report: ${response.statusCode}');
  }
});

final terminalStatusProvider = FutureProvider<List<dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/pos/terminals'),
    headers: _authHeaders(tenantId: tenantId),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch terminals: ${response.statusCode}');
  }
});

// ── Closed sessions (session history) ────────────────────────────────────────

final closedSessionsDateRangeProvider = StateProvider<DateTimeRange?>(
  (ref) => null,
);

final closedSessionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);
  final range = ref.watch(closedSessionsDateRangeProvider);

  final queryParams = <String, String>{};
  if (tenantId != null) queryParams['tenantId'] = tenantId;
  if (range != null) {
    queryParams['from'] = DateFormat('yyyy-MM-dd').format(range.start);
    queryParams['to'] = DateFormat('yyyy-MM-dd').format(range.end);
  }

  final uri = Uri.parse('${ApiConstants.baseUrl}/retail/sessions/reports')
      .replace(queryParameters: queryParams);
  final response = await http.get(
    uri,
    headers: _authHeaders(tenantId: tenantId),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch sessions: ${response.statusCode}');
  }
});

final sessionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) async {
  final tenantId = ref.watch(activeTenantProvider);
  final uri =
      Uri.parse('${ApiConstants.baseUrl}/retail/sessions/summary/$sessionId');
  final response = await http.get(
    uri,
    headers: _authHeaders(tenantId: tenantId),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch session detail: ${response.statusCode}');
  }
});

// ── Active sessions ───────────────────────────────────────────────────────────

final activeSessionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final tenantId = ref.watch(activeTenantProvider);

  final queryParams = <String, String>{};
  if (tenantId != null) queryParams['tenantId'] = tenantId;

  final uri = Uri.parse(
    '${ApiConstants.baseUrl}/retail/sessions/active',
  ).replace(queryParameters: queryParams);
  final response = await http.get(
    uri,
    headers: _authHeaders(tenantId: tenantId),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch active sessions: ${response.statusCode}');
  }
});

// ── KPI : clients actifs (total contacts dans la DB locale) ───────────────────

final activeClientCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(customerRepositoryProvider);
  final customers = await repo.getCustomers();
  return customers.length;
});
