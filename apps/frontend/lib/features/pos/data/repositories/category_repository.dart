import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/pos/data/models/category.dart';

class CategoryRepository {
  final IsarService _isarService;
  static const String _baseUrl = 'http://127.0.0.1:3000';

  CategoryRepository(this._isarService);

  Future<List<Category>> getCategories(String tenantId) async {
    final isar = await _isarService.db;
    return await isar.categorys.filter().tenantIdEqualTo(tenantId).findAll();
  }

  Future<Category> createCategory(String name, String tenantId) async {
    // Online-first for now, or optimistic UI?
    // Requirements say "Sync (Pull Only)" for categories in Story 5.2, but 
    // Story 4.3 (Product CRUD) implies we might need to select categories.
    // Dashboard (web) creates categories. POS (app) consumes them.
    // However, if we want to create categories on POS, we should support it.
    // For now, let's implement basic CREATE via API + Save Local
    
    final response = await http.post(
      Uri.parse('$_baseUrl/pos/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'tenantId': tenantId,
      }),
    );
    
    if (response.statusCode == 201) {
      final category = Category.fromJson(json.decode(response.body));
      final isar = await _isarService.db;
      await isar.writeTxn(() async {
        await isar.categorys.put(category);
      });
      return category;
    }
    throw Exception('Failed to create category');
  }

  Future<void> deleteCategory(String remoteId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/pos/categories/$remoteId'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
    
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.categorys.filter().remoteIdEqualTo(remoteId).deleteAll();
    });
  }

  Future<void> upsertCategories(List<Category> categories) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      for (final category in categories) {
        final existing = await isar.categorys.filter()
            .remoteIdEqualTo(category.remoteId)
            .findFirst();
        
        if (existing != null) {
          category.id = existing.id;
        }
        await isar.categorys.put(category);
      }
    });
  }
}
