import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/pos/data/models/customer.dart';

class CustomerRepository {
  final IsarService _isarService;
  static const String _baseUrl = 'http://127.0.0.1:3000';

  CustomerRepository(this._isarService);

  Future<List<Customer>> getCustomers() async {
    return _isarService.getAllCustomers();
  }

  Future<List<Customer>> searchRemoteCustomers(String tenantId, String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pos/customers/search?tenantId=$tenantId&q=$query'),
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
        Uri.parse('$_baseUrl/pos/customers'),
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
        Uri.parse('$_baseUrl/pos/customers?tenantId=$tenantId'),
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
        Uri.parse('$_baseUrl/pos/customers/$customerId/settle'),
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
}
