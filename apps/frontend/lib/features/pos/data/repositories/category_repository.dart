import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_state.dart';

class Category {
  final String id;
  final String name;
  final String tenantId;

  Category({
    required this.id,
    required this.name,
    required this.tenantId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      tenantId: json['tenantId'] as String,
    );
  }
}

class CategoryRepository {
  final String _baseUrl;

  CategoryRepository(this._baseUrl);

  Future<List<Category>> getCategories(String tenantId) async {
    final response = await http.get(Uri.parse('$_baseUrl/pos/categories?tenantId=$tenantId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<Category> createCategory(String name, String tenantId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pos/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'tenantId': tenantId,
      }),
    );
    if (response.statusCode == 201) {
      return Category.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create category');
  }

  Future<void> deleteCategory(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/pos/categories/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  // Use the same base URL as product repository
  return CategoryRepository('http://127.0.0.1:3000'); // TODO: Make configurable
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  final tenantId = ref.watch(activeTenantProvider);
  if (tenantId == null) return [];
  return repo.getCategories(tenantId);
});
