import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/pos/data/models/customer.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:isar/isar.dart';

class CustomerRepository {
  final IsarService _isarService;

  CustomerRepository(this._isarService);

  Future<List<Customer>> getCustomers() async {
    return _isarService.getAllCustomers();
  }

  Future<List<Customer>> searchRemoteCustomers(String tenantId, String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pos/customers/search?tenantId=$tenantId&q=$query'),
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

  Future<Customer> createCustomer(String tenantId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pos/customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenantId': tenantId,
          'data': data,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final customerData = jsonDecode(response.body);
        final customer = Customer.fromJson(customerData);
        await _isarService.saveCustomer(customer);
        return customer;
      } else {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      print('Error creating customer: $e');
      rethrow;
    }
  }

  Future<void> syncCustomers(String tenantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/pos/customers?tenantId=$tenantId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
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
        Uri.parse('${ApiConstants.baseUrl}/pos/customers/$customerId/settle'),
        headers: {'Content-Type': 'application/json'},
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
