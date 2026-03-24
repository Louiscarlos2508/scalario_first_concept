import 'dart:convert';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/features/shared/notifications/data/models/notification_model.dart';
import 'package:http/http.dart' as http;

class NotificationRepository {
  final http.Client _httpClient;
  final String? Function()? _tokenGetter;

  NotificationRepository({
    http.Client? httpClient,
    String? Function()? tokenGetter,
  })  : _httpClient = httpClient ?? http.Client(),
        _tokenGetter = tokenGetter;

  Map<String, String> _headers(String tenantId) {
    return ApiConstants.headers(
      tenantId: tenantId,
      token: _tokenGetter?.call(),
    );
  }

  /// GET /notifications?tenantId=&limit=&offset=
  Future<List<NotificationModel>> getNotifications(
    String tenantId, {
    int limit = 30,
    int offset = 0,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/notifications').replace(
      queryParameters: {
        'tenantId': tenantId,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    final res = await _httpClient.get(uri, headers: _headers(tenantId));
    if (res.statusCode != 200) {
      throw Exception('GET /notifications failed: ${res.statusCode}');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /notifications/unread-count?tenantId=
  Future<int> getUnreadCount(String tenantId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count')
        .replace(queryParameters: {'tenantId': tenantId});
    final res = await _httpClient.get(uri, headers: _headers(tenantId));
    if (res.statusCode != 200) return 0;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  /// POST /notifications/:id/read
  Future<void> markRead(String id, String tenantId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/notifications/$id/read');
    await _httpClient.post(uri, headers: _headers(tenantId));
  }

  /// PATCH /notifications/read-all?tenantId=
  Future<void> markAllRead(String tenantId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/notifications/read-all')
        .replace(queryParameters: {'tenantId': tenantId});
    await _httpClient.patch(uri, headers: _headers(tenantId));
  }
}
