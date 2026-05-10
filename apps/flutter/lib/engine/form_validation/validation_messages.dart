library;

/// French default error messages for each validation rule type.
///
/// AC-17: messages returned here are the last-resort fallback when neither
/// [ValidationRule.errorMessage] nor [ValidationRule.errorKey] is set.
///
/// AC-18: placeholders `{min}`, `{max}`, `{type}`, `{value}` are interpolated
/// by [ValidatorFactory] after message resolution.
final class ValidationMessages {
  const ValidationMessages();

  /// Returns the default French message template for [type].
  ///
  /// Placeholders in the returned string are filled by the caller.
  String defaultFor(String type) {
    return switch (type) {
      'required' || 'required_if' => 'Ce champ est requis',
      'min' => 'Valeur minimum : {min}',
      'max' => 'Valeur maximum : {max}',
      'minLength' => 'Au moins {min} caractères',
      'maxLength' => 'Maximum {max} caractères',
      'regex' => 'Format invalide',
      'enum' => 'Valeur non autorisée',
      'type' => 'Type {type} attendu',
      _ => 'Valeur invalide',
    };
  }
}
