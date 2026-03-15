import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/features/dashboard/data/models/sales_stat.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/core/constants/api_constants.dart';

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
  final response = await http.get(uri);

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
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch sales report: ${response.statusCode}');
  }
});

final terminalStatusProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await http.get(
    Uri.parse('${ApiConstants.baseUrl}/pos/terminals'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch terminals: ${response.statusCode}');
  }
});
