library;

/// Thrown when [ValidationRule.fromJson] encounters an invalid or unsupported
/// structure — e.g. unknown type, invalid regex, missing requiredIf node.
///
/// Always raised at **parse time** (not at validation time) so that bad JSON
/// is caught immediately when the form config is decoded, not silently at
/// the first user keystroke.
final class ValidationParseException implements Exception {
  const ValidationParseException(this.message);

  final String message;

  @override
  String toString() => 'ValidationParseException: $message';
}
