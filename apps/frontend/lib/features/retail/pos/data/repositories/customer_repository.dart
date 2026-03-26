import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/customer.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerRepository {
  final IsarService _isarService;

  CustomerRepository(this._isarService);

  Future<List<Customer>> getCustomers() async {
    return _isarService.getAllCustomers();
  }

  String? get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  Future<List<Customer>> searchRemoteCustomers(String tenantId, String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/contacts/search?tenantId=$tenantId&q=$query&contactType=customer'),
        headers: ApiConstants.headers(tenantId: tenantId, token: _token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Customer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching remote customers: $e');
      return [];
    }
  }

  Future<Customer> createContact({
    required String name,
    String? phone,
    String? email,
    required String contactType,
    required String tenantId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/contacts'),
      headers: ApiConstants.headers(tenantId: tenantId, token: _token),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'contactType': contactType,
        'tenantId': tenantId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final customer = Customer.fromJson(jsonDecode(response.body));
      await _isarService.saveCustomer(customer);
      return customer;
    }
    throw Exception('Échec création contact : ${response.body}');
  }

  Future<Customer> updateContact({
    required String id,
    String? name,
    String? phone,
    String? email,
    required String tenantId,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/contacts/$id'),
      headers: ApiConstants.headers(tenantId: tenantId, token: _token),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final customer = Customer.fromJson(jsonDecode(response.body));
      await _isarService.saveCustomer(customer);
      return customer;
    }
    throw Exception('Échec mise à jour contact : ${response.body}');
  }

  Future<void> deleteContact({
    required String id,
    required String tenantId,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/contacts/$id'),
      headers: ApiConstants.headers(tenantId: tenantId, token: _token),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 204 &&
        response.statusCode != 201) {
      throw Exception('Échec suppression contact : ${response.body}');
    }
  }

  // Kept for backward compat (used by contact_sync_adapter offline push)
  Future<Customer> createCustomer(String tenantId, Map<String, dynamic> data) async {
    return createContact(
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      contactType: data['contactType']?.toString() ?? 'customer',
      tenantId: tenantId,
    );
  }

  Future<void> syncCustomers(String tenantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/contacts?tenantId=$tenantId&contactType=customer'),
        headers: ApiConstants.headers(tenantId: tenantId, token: _token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data =
            body is Map ? (body['items'] as List? ?? []) : body as List;
        final customers = data.map((json) => Customer.fromJson(json)).toList();
        await _isarService.saveCustomers(customers);
      }
    } catch (e) {
      print('Error syncing customers: $e');
    }
  }

  Future<void> settleDebt(String customerId, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/contacts/$customerId/settle'),
        headers: ApiConstants.headers(token: _token),
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final customerData = jsonDecode(response.body);
        final customer = Customer.fromJson(customerData);
        await _isarService.saveCustomer(customer);
      } else {
        throw Exception('Failed to settle debt: ${response.body}');
      }
    } catch (e) {
      print('Error settling debt: $e');
      rethrow;
    }
  }

  Future<void> incrementLocalBalance(String remoteId, double amount) async {
    await _isarService.incrementCustomerBalance(remoteId, amount);
  }

  Future<List<Customer>> getPendingCustomers() async {
    final isar = await _isarService.db;
    return await isar.customers.filter().uuidIsNotEmpty().remoteIdIsNull().findAll();
  }

  Future<void> markAsSynced(String uuid, String remoteId) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final customer = await isar.customers.filter().uuidEqualTo(uuid).findFirst();
      if (customer != null) {
        customer.remoteId = remoteId;
        customer.isSynced = true;
        customer.lastUpdated = DateTime.now();
        await isar.customers.put(customer);
      }
    });
  }

  Future<void> clearLocalCustomers() async {
    await _isarService.cleanCustomers();
  }

  Future<void> upsertCustomers(List<Customer> customers) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      for (final customer in customers) {
        final existing = await isar.customers.filter()
            .remoteIdEqualTo(customer.remoteId)
            .findFirst();
        
        if (existing != null) {
          customer.id = existing.id;
          // Preserve local pending changes if any (conflict resolution strategy: server wins for now)
        }
        await isar.customers.put(customer);
      }
    });
  }
}
