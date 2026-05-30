import 'package:dio/dio.dart';

class AiRelayResponse {
  const AiRelayResponse({
    required this.surfaceId,
    required this.messages,
    required this.model,
    required this.degraded,
  });

  final String surfaceId;
  final List<Map<String, dynamic>> messages;
  final String model;
  final bool degraded;

  factory AiRelayResponse.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    return AiRelayResponse(
      surfaceId: (json['surfaceId'] ?? '').toString(),
      messages: rawMessages.cast<Map<String, dynamic>>(),
      model: (json['model'] ?? '').toString(),
      degraded: (json['degraded'] ?? false) == true,
    );
  }
}

class AiRelayClient {
  AiRelayClient({required String baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl.replaceAll(RegExp(r'/+$'), ''),
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        ));

  final Dio _dio;

  Future<AiRelayResponse> generate({
    required String tenantId,
    required String surfaceId,
    required String intent,
    Map<String, dynamic>? context,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/$tenantId/ai-relay/dev/generate',
      data: {
        'surfaceId': surfaceId,
        'intent': intent,
        if (context != null) 'context': context,
      },
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from AI Relay');
    }

    return AiRelayResponse.fromJson(data);
  }

  void dispose() {
    _dio.close();
  }
}
