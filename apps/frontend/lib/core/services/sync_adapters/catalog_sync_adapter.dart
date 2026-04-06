import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/services/sync_adapters/sync_adapter.dart';
import 'package:frontend/core/services/sync_auth_exception.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/data/models/category.dart';
import 'package:frontend/features/retail/pos/data/repositories/product_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/category_repository.dart';
import 'package:frontend/features/retail/pos/data/repositories/session_repository.dart';

/// Handles product (catalog) and category push/pull.
/// Products are pull-only (created via Dashboard, not POS).
/// Categories are pull-only (created via Dashboard, not POS).
///
/// ## Fix 2 — Server timestamp
/// Reads [_kSyncTimestampHeader] from GET response headers and stores that
/// server-authoritative timestamp as the `since` cursor for future delta pulls.
/// Falls back to [DateTime.now] if the header is absent (server not yet updated).
///
/// ## Fix 4 — JWT 401 handling
/// Throws [SyncAuthException] on 401/403 so the sync engine can suspend and
/// trigger a silent token refresh.
class CatalogSyncAdapter implements SyncAdapter {
  final ProductRepository _productRepo;
  final CategoryRepository _categoryRepo;
  final SessionRepository _sessionRepo;

  static const _kSyncTimestampHeader = 'x-sync-timestamp';

  CatalogSyncAdapter({
    required ProductRepository productRepo,
    required CategoryRepository categoryRepo,
    required SessionRepository sessionRepo,
  })  : _productRepo = productRepo,
        _categoryRepo = categoryRepo,
        _sessionRepo = sessionRepo;

  /// Products and categories are pull-only — no pending items to push.
  @override
  Future<void> pushPending(String baseUrl, String tenantId,
      {String? token}) async {
    // No outbox for catalog items — created/modified from Dashboard only.
  }

  /// Pull products and categories.
  /// When [since] is null (forceFullPull), replaces all local data instead of
  /// upserting — clears stale/offline-created entries.
  @override
  Future<void> pullDelta(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    final forceFullPull = since == null;
    await _pullProducts(baseUrl, tenantId, since, token: token);
    final lastCategorySync =
        forceFullPull ? null : await _sessionRepo.getLastSync('categories');
    await _pullCategories(baseUrl, tenantId, lastCategorySync,
        forceFullPull: forceFullPull, token: token);
  }

  Future<void> _pullProducts(String baseUrl, String tenantId, DateTime? since,
      {String? token}) async {
    final sinceStr = since?.toUtc().toIso8601String() ?? '';
    final url =
        '$baseUrl/pos/products?limit=10000&tenantId=$tenantId${sinceStr.isNotEmpty ? '&since=$sinceStr' : ''}';

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-tenant-id': tenantId,
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      // Fix 4 — 401/403 suspend le sync.
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw SyncAuthException(response.statusCode);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];
        final products = items.map((j) => Product.fromJson(j)).toList();

        if (products.isNotEmpty) {
          if (since == null) {
            await _productRepo.replaceProducts(products);
            print('[CatalogAdapter] Full replace: ${products.length} products');
          } else {
            await _productRepo.upsertProducts(products);
            print('[CatalogAdapter] Delta upsert: ${products.length} products');
          }
        }

        // Fix 2 — curseur = timestamp serveur, pas DateTime.now().
        final serverTs = _parseServerTimestamp(response.headers);
        await _sessionRepo.updateLastSync('products', serverTs);
      }
    } catch (e) {
      if (e is SyncAuthException) rethrow;
      print('[CatalogAdapter] Product pull failed: $e');
      rethrow;
    }
  }

  Future<void> _pullCategories(String baseUrl, String tenantId, DateTime? since,
      {bool forceFullPull = false, String? token}) async {
    final sinceStr = since?.toUtc().toIso8601String() ?? '';
    final url =
        '$baseUrl/pos/categories?tenantId=$tenantId${sinceStr.isNotEmpty ? '&since=$sinceStr' : ''}';
    final headers = {
      'Content-Type': 'application/json',
      'x-tenant-id': tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      // Fix 4
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw SyncAuthException(response.statusCode);
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final categories = data.map((j) => Category.fromJson(j)).toList();
        if (categories.isNotEmpty) {
          if (forceFullPull) {
            await _categoryRepo.clearCategories();
            await _categoryRepo.saveCategories(categories);
            print(
                '[CatalogAdapter] Full replace: ${categories.length} categories');
          } else {
            await _categoryRepo.upsertCategories(categories);
            print(
                '[CatalogAdapter] Delta upsert: ${categories.length} categories');
          }
        }

        // Fix 2 — curseur serveur.
        final serverTs = _parseServerTimestamp(response.headers);
        await _sessionRepo.updateLastSync('categories', serverTs);
      }
    } catch (e) {
      if (e is SyncAuthException) rethrow;
      print('[CatalogAdapter] Category pull failed: $e');
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
