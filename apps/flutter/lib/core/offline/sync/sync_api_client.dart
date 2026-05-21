import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class SyncApiError implements Exception {
  const SyncApiError({
    required this.message,
    this.statusCode,
    this.isRetryable = false,
  });

  final String message;
  final int? statusCode;
  final bool isRetryable;

  @override
  String toString() => 'SyncApiError($statusCode): $message';
}

class SyncApiClient {
  SyncApiClient({
    required String baseUrl,
    required Future<String?> Function() tokenProvider,
  })  : _tokenProvider = tokenProvider,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl.replaceAll(RegExp(r'/+$'), ''),
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _tokenProvider();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            developer.log(
              'Token provider failed: $e',
              name: 'Scalario.Offline.Sync',
              level: 900,
            );
          }
          options.headers['Content-Type'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) {
          developer.log(
            'SyncApiClient error: ${error.message}',
            name: 'Scalario.Offline.Sync',
            level: 900,
          );
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;
  final Future<String?> Function() _tokenProvider;

  Future<BatchSyncResponse> postMutations({
    required String tenantSlug,
    required List<SyncMutationPayload> mutations,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/$tenantSlug/sync/mutations',
        data: {
          'mutations': mutations
              .map((m) => <String, dynamic>{
                    'mutation_id': m.mutationId,
                    'module_id': m.moduleId,
                    'action': m.action,
                    'payload': m.payload,
                  })
              .toList(),
        },
      );

      final data = response.data;
      if (data == null || data['results'] == null) {
        return const BatchSyncResponse(results: []);
      }

      final resultsList = data['results'];
      if (resultsList is! List) {
        return const BatchSyncResponse(results: []);
      }

      final List<SyncResultItem> results = [];
      for (final dynamic r in resultsList) {
        if (r is! Map<String, dynamic>) continue;
        results.add(SyncResultItem(
          mutationId: (r['mutation_id'] ?? '').toString(),
          status: (r['status'] ?? 'error').toString(),
          entity: r['entity'] as Map<String, dynamic>?,
          error: r['error']?.toString(),
        ));
      }
      return BatchSyncResponse(results: results);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.message ?? 'Dio error';
      final type = e.type;

      final isNetworkError = type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.receiveTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.connectionError;
      final isRetryable = isNetworkError ||
          (statusCode != null && (statusCode >= 500 || statusCode == 429 || statusCode == 408));

      throw SyncApiError(
        message: 'HTTP $statusCode: $message',
        statusCode: statusCode,
        isRetryable: isRetryable,
      );
    }
  }

  void dispose() {
    _dio.close();
  }
}

class SyncMutationPayload {
  const SyncMutationPayload({
    required this.mutationId,
    required this.moduleId,
    required this.action,
    required this.payload,
  });

  final String mutationId;
  final String moduleId;
  final String action;
  final Map<String, dynamic> payload;
}

class BatchSyncResponse {
  const BatchSyncResponse({required this.results});

  final List<SyncResultItem> results;
}

class SyncResultItem {
  const SyncResultItem({
    required this.mutationId,
    required this.status,
    this.entity,
    this.error,
  });

  final String mutationId;
  final String status;
  final Map<String, dynamic>? entity;
  final String? error;
}
