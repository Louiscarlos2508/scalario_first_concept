import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/shared/reports/data/models/sales_stat.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

Map<String, String> _authHeaders({String? tenantId}) {
  final token = Supabase.instance.client.auth.currentSession?.accessToken;
  return {
    'Content-Type': 'application/json',
    if (tenantId != null) 'x-tenant-id': tenantId,
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

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
    // Backend returns a flat aggregate object — wrap into a single daily entry.
    if (decoded is Map<String, dynamic>) {
      return [
        SalesStat(
          day: DateTime.now(),
          revenue: (decoded['totalRevenue'] as num?)?.toDouble() ?? 0,
          orderCount: (decoded['saleCount'] as num?)?.toInt() ?? 0,
        ),
      ];
    }
    // Future: backend returns array of daily stats
    return (decoded as List<dynamic>)
        .map((json) => SalesStat.fromJson(json as Map<String, dynamic>))
        .toList();
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
