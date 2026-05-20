sealed class ValidationResult {
  const ValidationResult();
}

final class Valid extends ValidationResult {
  const Valid();
}

final class Invalid extends ValidationResult {
  final List<ValidationError> errors;
  const Invalid(this.errors);
}

class ValidationError {
  final String path;
  final String message;
  final String keyword;

  const ValidationError({
    required this.path,
    required this.message,
    required this.keyword,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationError &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          message == other.message &&
          keyword == other.keyword;

  @override
  int get hashCode => Object.hash(path, message, keyword);

  @override
  String toString() => 'ValidationError(path: $path, keyword: $keyword, message: $message)';
}
