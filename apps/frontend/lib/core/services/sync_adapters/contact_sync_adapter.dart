import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/core/services/sync_auth_exception.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/features/retail/pos/data/repositories/customer_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';

/// Handles customer (contact) push/pull.
///
/// ## Fix 4 — JWT 401 handling
/// Throws [SyncAuthException] on 401/403 in push and pull paths.
///
/// ## Fix 2 — Server timestamp
/// Reads [_kSyncTimestampHeader] from GET response headers and stores that
/// server-authoritative timestamp as the `since` cursor for future delta pulls.
/// Falls back to [DateTime.now] if the header is absent.
class ContactSyncAdapter implements SyncAdapter {
  final CustomerRepository _customerRepo;
  final SessionRepository _sessionRepo;

  static const _kSyncTimestampHeader = 'x-sync-timestamp';

  ContactSyncAdapter({
    required CustomerRepository customerRepo,
    required SessionRepository sessionRepo,
  })  : _customerRepo = customerRepo,
        _sessionRepo = sessionRepo;

  /// Push locally created customers (uuid set, remoteId null) to the server.
  ///
  /// Throws [SyncAuthException] on 401/403.
  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    final pendingCustomers = await _customerRepo.getPendingCustomers();
    if (pendingCustomers.isEmpty) return;

    debugPrint(
        '[ContactAdapter] Pushing ${pendingCustomers.length} pending customers');

    for (final customer in pendingCustomers) {
      if (customer.tenantId == null || customer.tenantId!.isEmpty) continue;

      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/contacts'),
              headers: {
                'Content-Type': 'application/json',
                'x-tenant-id': tenantId,
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'name': customer.name,
                'phone': customer.phone,
                'email': customer.email,
                'address': customer.address,
                'contactType': customer.contactType ?? 'customer',
                'tenantId': customer.tenantId,
              }),
            )
            .timeout(const Duration(seconds: 10));

        // Fix 4 — 401/403 suspend le sync, le reste des clients n'est pas poussé.
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw SyncAuthException(response.statusCode);
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final remoteId = data['id']?.toString();
          if (remoteId != null) {
            await _customerRepo.markAsSynced(customer.uuid, remoteId);
          }
        }
      } catch (e) {
        if (e is SyncAuthException) rethrow;
        debugPrint(
            '[ContactAdapter] Failed to push customer ${customer.uuid}: $e');
      }
    }
  }

  /// Pull customers delta since [since].
  ///
  /// ## Fix 2 — timestamp serveur
  /// Le curseur `since` stocké localement est mis à jour avec le timestamp
  /// retourné par le serveur dans [_kSyncTimestampHeader] (pas [DateTime.now]).
  /// Cela élimine la dérive d'horloge entre le device et le serveur.
  ///
  /// Throws [SyncAuthException] on 401/403.
  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    final sinceStr = since?.toUtc().toIso8601String() ?? '';
    final url =
        '$baseUrl/contacts?tenantId=$tenantId&contactType=customer${sinceStr.isNotEmpty ? '&since=$sinceStr' : ''}';
    final headers = {
      'Content-Type': 'application/json',
      'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      // Fix 4 — 401 sur le pull = exception typée.
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw SyncAuthException(response.statusCode);
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data =
            body is Map ? (body['items'] as List? ?? []) : body as List;
        final customers = data.map((j) => Customer.fromJson(j)).toList();

        if (since == null) {
          await _customerRepo.clearLocalCustomers();
        }

        if (customers.isNotEmpty) {
          await _customerRepo.upsertCustomers(customers);
          debugPrint('[ContactAdapter] Upserted ${customers.length} customers');
        }

        // Fix 2 — utiliser le timestamp serveur comme curseur, pas DateTime.now().
        final serverTs = _parseServerTimestamp(response.headers);
        await _sessionRepo.updateLastSync('customers', serverTs);
      }
    } catch (e) {
      if (e is SyncAuthException) rethrow;
      debugPrint('[ContactAdapter] Customer pull failed: $e');
      rethrow;
    }
  }

  /// Extrait [_kSyncTimestampHeader] du header de réponse.
  /// Fallback sur [DateTime.now().toUtc()] si absent ou non parseable.
  DateTime _parseServerTimestamp(Map<String, String> headers) {
    final raw = headers[_kSyncTimestampHeader];
    if (raw != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }
}
