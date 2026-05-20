import '../../core/bdui/validation/validation_result.dart';

class BduiInvalidPayloadException implements Exception {
  final List<ValidationError> errors;
  final String? screenId;
  final String? endpoint;
  final String payloadHash;

  const BduiInvalidPayloadException({
    required this.errors,
    this.screenId,
    this.endpoint,
    required this.payloadHash,
  });

  @override
  String toString() =>
      'BduiInvalidPayloadException: ${errors.length} error(s) on ${screenId ?? endpoint ?? "unknown"} (hash: $payloadHash)';
}
