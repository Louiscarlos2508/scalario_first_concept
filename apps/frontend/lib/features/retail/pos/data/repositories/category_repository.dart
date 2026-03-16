import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/pos/data/models/category.dart';
import 'package:frontend/core/constants/api_constants.dart';

class CategoryRepository {
  final IsarService _isarService;

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
      Uri.parse('${ApiConstants.baseUrl}/pos/categories'),
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
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/pos/categories/$remoteId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    // 404 = already gone on server; still delete locally.
    if (response.statusCode != 200 &&
        response.statusCode != 204 &&
        response.statusCode != 404) {
      throw Exception('Erreur suppression (${response.statusCode})');
    }

    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.categorys.filter().remoteIdEqualTo(remoteId).deleteAll();
    });
  }

  Future<void> clearCategories() async {
    await _isarService.clearCategories();
  }

  Future<void> saveCategories(List<Category> categories) async {
    await _isarService.saveCategories(categories);
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
