import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/services/isar_service.dart';
import 'package:frontend/features/retail/inventory/data/models/inventory_movement_local.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';

class InventoryRepository {
  final http.Client _httpClient;
  final IsarService? _isarService;
  final String? Function()? _tokenGetter;

  InventoryRepository({
    http.Client? httpClient,
    IsarService? isarService,
    String? Function()? tokenGetter,
  })  : _httpClient = httpClient ?? http.Client(),
        _isarService = isarService,
        _tokenGetter = tokenGetter;

  Map<String, String> _authHeaders({String? tenantId, String? token}) {
    final accessToken = token ?? _tokenGetter?.call();
    return ApiConstants.headers(tenantId: tenantId, token: accessToken);
  }

  /// POST /inventory/movements
  Future<Map<String, dynamic>> createMovement({
    required String type,
    required String catalogItemId,
    required int quantity,
    String? reason,
    String? referenceId,
    required String tenantId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'catalogItemId': catalogItemId,
      'quantity': quantity,
      'tenantId': tenantId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (referenceId != null) 'referenceId': referenceId,
    };

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/inventory/movements'),
      headers: _authHeaders(tenantId: tenantId, token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'createMovement failed: ${response.statusCode} — ${response.body}',
    );
  }

  /// GET /inventory/movements?tenantId=&type=TRANSFER_OUT
  Future<List<Map<String, dynamic>>> getPendingTransfers({
    required String tenantId,
    String? token,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/inventory/movements',
    ).replace(queryParameters: {
      'tenantId': tenantId,
      'type': 'TRANSFER_OUT',
    });

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId, token: token),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic>) {
        items = (decoded['items'] as List<dynamic>?) ?? [];
      } else {
        items = [];
      }
      return items.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'getPendingTransfers failed: ${response.statusCode} — ${response.body}',
    );
  }

  /// GET /inventory/stock?catalogItemId=&tenantId=
  Future<int> getStock({
    required String catalogItemId,
    required String tenantId,
    String? token,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/inventory/stock',
    ).replace(queryParameters: {
      'catalogItemId': catalogItemId,
      'tenantId': tenantId,
    });

    final response = await _httpClient.get(
      uri,
      headers: _authHeaders(tenantId: tenantId, token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['currentStock'];
      if (raw is int) return raw;
      return int.tryParse(raw.toString()) ?? 0;
    }

    throw Exception(
      'getStock failed: ${response.statusCode} — ${response.body}',
    );
  }

  /// POST /inventory/adjust
  Future<Map<String, dynamic>> adjustStock({
    required String catalogItemId,
    required int countedQuantity,
    required String reason,
    required String tenantId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'catalogItemId': catalogItemId,
      'countedQuantity': countedQuantity,
      'reason': reason,
      'tenantId': tenantId,
    };

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/inventory/adjust'),
      headers: _authHeaders(tenantId: tenantId, token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'adjustStock failed: ${response.statusCode} — ${response.body}',
    );
  }

  /// POST /inventory/movements/confirm
  Future<Map<String, dynamic>> confirmTransfer({
    required String referenceId,
    String? catalogItemId,
    required int quantity,
    required String tenantId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      'referenceId': referenceId,
      'quantity': quantity,
      'tenantId': tenantId,
      if (catalogItemId != null) 'catalogItemId': catalogItemId,
    };

    final response = await _httpClient.post(
      Uri.parse('${ApiConstants.baseUrl}/inventory/movements/confirm'),
      headers: _authHeaders(tenantId: tenantId, token: token),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'confirmTransfer failed: ${response.statusCode} — ${response.body}',
    );
  }

  // ─── Local (Isar) methods ────────────────────────────────────────────────

  Future<void> saveLocal(InventoryMovementLocal movement) async {
    if (_isarService == null) return;
    final isar = await _isarService.db;
    await isar.writeTxn(() => isar.inventoryMovementLocals.put(movement));
  }

  Future<List<InventoryMovementLocal>> getPendingMovements() async {
    if (_isarService == null) return [];
    final isar = await _isarService.db;
    return isar.inventoryMovementLocals
        .where()
        .syncStatusEqualTo('pending')
        .findAll();
  }

  Future<void> markSynced(int id, String remoteId) async {
    if (_isarService == null) return;
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final m = await isar.inventoryMovementLocals.get(id);
      if (m != null) {
        m
          ..syncStatus = 'synced'
          ..remoteId = remoteId;
        await isar.inventoryMovementLocals.put(m);
      }
    });
  }

  Future<void> markFailed(int id, String error) async {
    if (_isarService == null) return;
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      final m = await isar.inventoryMovementLocals.get(id);
      if (m != null) {
        m
          ..syncStatus = 'failed'
          ..errorMessage = error;
        await isar.inventoryMovementLocals.put(m);
      }
    });
  }

  Future<List<InventoryMovementLocal>> getMovements({
    String? type,
    int limit = 20,
  }) async {
    final isar = await _isarService!.db;
    List<InventoryMovementLocal> results;
    if (type != null) {
      results = await isar.inventoryMovementLocals
          .where()
          .typeEqualTo(type)
          .findAll();
    } else {
      results = await isar.inventoryMovementLocals.where().findAll();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results.take(limit).toList();
  }
}
