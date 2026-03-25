import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';

/// Handles customer (contact) push/pull.
class ContactSyncAdapter implements SyncAdapter {
  final CustomerRepository _customerRepo;
  final SessionRepository _sessionRepo;

  ContactSyncAdapter({
    required CustomerRepository customerRepo,
    required SessionRepository sessionRepo,
  })  : _customerRepo = customerRepo,
        _sessionRepo = sessionRepo;

  /// Push locally created customers (uuid set, remoteId null) to the server.
  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pendingCustomers = await _customerRepo.getPendingCustomers();
    if (pendingCustomers.isEmpty) return;

    print('[ContactAdapter] Pushing ${pendingCustomers.length} pending customers');

    for (final customer in pendingCustomers) {
      if (customer.tenantId == null || customer.tenantId!.isEmpty) continue;

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/pos/customers'),
              headers: {
                'Content-Type': 'application/json',
                'x-tenant-id': tenantId,
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'tenantId': customer.tenantId,
                'data': customer.toJson(),
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final remoteId = data['id']?.toString();
          if (remoteId != null) {
            await _customerRepo.markAsSynced(customer.uuid, remoteId);
          }
        }
      } catch (e) {
        print('[ContactAdapter] Failed to push customer ${customer.uuid}: $e');
      }
    }
  }

  /// Pull customers delta since [since].
  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    final sinceStr = since?.toUtc().toIso8601String() ?? '';
    final url =
        '$baseUrl/pos/customers?tenantId=$tenantId${sinceStr.isNotEmpty ? '&since=$sinceStr' : ''}';
    final headers = {
      'Content-Type': 'application/json',
      'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final customers = data.map((j) => Customer.fromJson(j)).toList();

        // Full sync (since == null) : remplacer tout le cache local
        if (since == null) {
          await _customerRepo.clearLocalCustomers();
        }

        if (customers.isNotEmpty) {
          await _customerRepo.upsertCustomers(customers);
          print('[ContactAdapter] Upserted ${customers.length} customers');
        }

        await _sessionRepo.updateLastSync('customers', DateTime.now().toUtc());
      }
    } catch (e) {
      print('[ContactAdapter] Customer pull failed: $e');
      rethrow;
    }
  }
}
