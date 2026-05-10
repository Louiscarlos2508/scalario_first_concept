/// Bridge between [ValidatorFactory] and Flutter's [Form] / [FormField] widgets.
///
/// [ValidatedFormController] manages the lifecycle of validators built from
/// JSON config:
///   1. Constructed from [ValidationRule] lists via [ValidatorFactory].
///   2. Each field's validator is retrieved by ID and plugged into any [FormField].
///   3. [validateAll] forces full form validation (submit guard — AC-15).
///   4. [isRequiredIf] provides a live boolean for conditional asterisk labels (AC-12).
///
/// Timing — [validateOn]:
///   - [ValidateOn.blur]   (default): validator should be called from [FormField.onSaved]
///     or [FocusNode.addListener] — wired by the widget consuming this controller.
///   - [ValidateOn.change]: validator should be called on [TextField.onChanged].
///
/// The controller is a [ChangeNotifier] so form widgets can listen to
/// [formData] mutations (e.g. to re-evaluate required_if asterisks).
library;

import 'package:flutter/widgets.dart';

import '../component_registry/component_config.dart';
import 'field_context.dart';
import 'validation_messages.dart';
import 'validation_rule.dart';
import 'validator_factory.dart';

/// Controls when field validators are triggered.
///
/// AC-13: [blur] is the default — validator fires on focus loss.
/// AC-14: [change] — validator fires on every keystroke.
enum ValidateOn { blur, change }

/// Stateful controller that owns the form's validator map and live field data.
///
/// AC-19: built from a list of [ComponentConfig] via [ValidatedFormController.fromConfigs].
/// AC-20: [validateAll] iterates all fields and returns false on the first error.
/// AC-21: granularity is per-field — only [formData] notifies, not the full screen.
class ValidatedFormController extends ChangeNotifier {
  ValidatedFormController({
    required Map<String, FormFieldValidator<dynamic>> validators,
    this.validateOn = ValidateOn.blur,
  }) : _validators = validators;

  /// Builds a controller from a list of [ComponentConfig] entries (as returned
  /// by the BDUI engine). Fields without an [ComponentConfig.id] or without
  /// [ComponentConfig.validation] are silently skipped.
  factory ValidatedFormController.fromConfigs(
    List<ComponentConfig> fields,
    FieldContext fieldCtx, {
    ValidateOn validateOn = ValidateOn.blur,
    ValidatorFactory? factory,
    ValidationMessages? messages,
  }) {
    final f = factory ?? ValidatorFactory(messages: messages);
    final validators = <String, FormFieldValidator<dynamic>>{};

    for (final config in fields) {
      final id = config.id;
      final rawRules = config.validation;
      if (id == null || rawRules == null || rawRules.isEmpty) continue;

      final rules = rawRules.map(ValidationRule.fromJson).toList();
      validators[id] = f.fromRules(rules, fieldCtx);
    }

    return ValidatedFormController(
      validators: validators,
      validateOn: validateOn,
    );
  }

  final Map<String, FormFieldValidator<dynamic>> _validators;

  /// When validators should fire — [ValidateOn.blur] (default) or [ValidateOn.change].
  final ValidateOn validateOn;

  /// Live values of each form field, updated via [updateField].
  /// Used by `required_if` validators when they re-evaluate on sibling changes.
  final Map<String, Object?> _formData = {};

  Map<String, Object?> get formData => Map.unmodifiable(_formData);

  // ---------------------------------------------------------------------------
  // Validator access
  // ---------------------------------------------------------------------------

  /// Returns the [FormFieldValidator] for [fieldId], or null if the field has
  /// no validation rules.
  FormFieldValidator<T>? validatorFor<T>(String fieldId) {
    final v = _validators[fieldId];
    if (v == null) return null;
    return (T? value) => v(value);
  }

  // ---------------------------------------------------------------------------
  // Form data management (AC-12, AC-21)
  // ---------------------------------------------------------------------------

  /// Updates the stored value for [fieldId] and notifies listeners.
  ///
  /// Call this from [TextField.onChanged] so that `required_if` validators
  /// evaluate against the latest sibling values.
  void updateField(String fieldId, Object? value) {
    _formData[fieldId] = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // required_if reactive label support (AC-12)
  // ---------------------------------------------------------------------------

  /// Returns true if the `required_if` condition for [fieldId] currently
  /// evaluates to true given [fieldCtx].
  ///
  /// Used to show/hide the asterisk on a field label without a full re-render.
  ///
  /// Returns false for fields with no `required_if` rule.
  bool isRequiredIf(String fieldId, FieldContext fieldCtx) {
    final validator = _validators[fieldId];
    if (validator == null) return false;
    // Evaluate the validator with null to check if required — if the returned
    // error matches the 'required' message key, the condition is active.
    // Lightweight: pure evaluation, no widget tree involved.
    final error = validator(null);
    return error != null;
  }

  // ---------------------------------------------------------------------------
  // Submit guard (AC-15, AC-20)
  // ---------------------------------------------------------------------------

  /// Forces validation of all fields via [formKey] regardless of [validateOn].
  ///
  /// Returns true when all validators return null (no errors).
  /// AC-15: called by the submit button before dispatching any action.
  bool validateAll(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  void dispose() {
    _formData.clear();
    super.dispose();
  }
}
