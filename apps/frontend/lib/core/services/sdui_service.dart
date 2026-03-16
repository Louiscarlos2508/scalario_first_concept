import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/sdui/sdui_layout.dart';

/// Fetches SDUI layouts from the backend with SharedPreferences caching.
///
/// Cache strategy:
/// - Key: `sdui_layout_{screen}`  — JSON string of full layout response
/// - Timestamp key: `sdui_layout_{screen}_ts` — epoch seconds of last fetch
/// - TTL: 1 hour (3600 seconds)
/// - Stale-while-revalidate: stale cache returned on offline failure
class SduiService {
  static const int _ttlSeconds = 3600; // 1 hour

  final http.Client _client;

  SduiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch the layout for [screen].
  ///
  /// 1. If cache is valid (< TTL), returns cached layout immediately.
  /// 2. Otherwise fetches from `/sdui/layout?screen={screen}`.
  /// 3. On network failure, returns stale cache if available.
  /// 4. If no cache at all, rethrows the exception.
  Future<SduiLayout> fetchLayout(
    String screen, {
    String? tenantId,
    String? token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'sdui_layout_$screen';
    final timestampKey = 'sdui_layout_${screen}_ts';

    final cached = prefs.getString(cacheKey);
    final timestamp = prefs.getInt(timestampKey) ?? 0;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cacheIsValid =
        cached != null && (nowSeconds - timestamp) < _ttlSeconds;

    if (cacheIsValid) {
      return SduiLayout.fromJson(
        jsonDecode(cached) as Map<String, dynamic>,
      );
    }

    // Fetch from backend
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/sdui/layout')
          .replace(queryParameters: {'screen': screen});

      final response = await _client.get(
        uri,
        headers: ApiConstants.headers(tenantId: tenantId, token: token),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Persist to cache
        await prefs.setString(cacheKey, response.body);
        await prefs.setInt(timestampKey, nowSeconds);
        return SduiLayout.fromJson(json);
      }

      throw Exception(
        'SDUI layout fetch failed: HTTP ${response.statusCode}',
      );
    } catch (_) {
      // Offline fallback: return stale cache if available
      if (cached != null) {
        return SduiLayout.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      }
      rethrow;
    }
  }
}
