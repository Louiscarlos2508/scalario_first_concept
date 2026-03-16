import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/retail/dashboard/data/models/sales_stat.dart';
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

final salesStatsDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final salesStatsProvider = FutureProvider<List<SalesStat>>((ref) async {
  final range = ref.watch(salesStatsDateRangeProvider);
  final tenantId = ref.watch(activeTenantProvider);

  String url = '${ApiConstants.baseUrl}/reports/sales/stats';
  final queryParams = <String, String>{};

  if (range != null) {
    queryParams['start'] = DateFormat('yyyy-MM-dd').format(range.start);
    queryParams['end'] = DateFormat('yyyy-MM-dd').format(range.end);
  }

  if (tenantId != null) {
    queryParams['tenantId'] = tenantId;
  }

  final uri = Uri.parse(url).replace(queryParameters: queryParams);
  final response = await http.get(uri, headers: _authHeaders(tenantId: tenantId));

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => SalesStat.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch sales stats: ${response.statusCode}');
  }
});

final salesReportDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

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
  final response = await http.get(uri, headers: _authHeaders(tenantId: tenantId));

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
