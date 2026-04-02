class ApiConstants {
  ApiConstants._(); // prevent instantiation

  static const String _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1:3000',
  );
  static const String baseUrl = 'http://$_apiHost';

  /// Build request headers. Includes Content-Type always.
  /// x-tenant-id and Authorization are added only when provided.
  static Map<String, String> headers({String? tenantId, String? token}) {
    return {
      'Content-Type': 'application/json',
      'x-tenant-id': ?tenantId,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
