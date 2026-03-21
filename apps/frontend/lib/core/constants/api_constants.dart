class ApiConstants {
  ApiConstants._(); // prevent instantiation

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

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
