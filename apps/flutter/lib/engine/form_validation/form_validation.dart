/// BDUI Form Validation engine — data-driven validators from JSON config.
///
/// Entry point:
///   1. Parse rules from JSON: `ValidationRule.fromJson(map)`.
///   2. Build a validator: `ValidatorFactory().fromRules(rules, fieldCtx)`.
///   3. Plug into any Flutter FormField: `TextFormField(validator: validator)`.
///
/// For full-form lifecycle management use [ValidatedFormController], which
/// wraps the map of validators, tracks live field data, and provides
/// [ValidatedFormController.validateAll] for the submit guard.
library;

export 'field_context.dart';
export 'form_widget_validation_extension.dart';
export 'validation_exception.dart';
export 'validation_messages.dart';
export 'validation_rule.dart';
export 'validator_factory.dart';
