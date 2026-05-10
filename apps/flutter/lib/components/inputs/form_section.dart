import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../feedback/alert_banner.dart';

/// Erreur de validation d'un champ d'un `FormSection`.
///
/// Le widget `FormSection` n'effectue **aucune** validation — il **affiche**
/// les erreurs reçues. La validation vit ailleurs (STORY-023 JSON Schema).
class FormFieldError {
  const FormFieldError({required this.fieldKey, required this.message});

  final String fieldKey;
  final String message;
}

/// Section de formulaire — titre overline + hint optionnel + colonne de champs.
///
/// **Spec source :** `design-process/D-Design-System/components/03-inputs.md`
/// (variante FormWidget — section regroupée).
///
/// **États supportés :** Normal, Avec hint, Avec erreurs, Loading
/// (champs visuellement disabled, callbacks ignorés via `IgnorePointer`).
///
/// **Note Sprint 1 :** les champs eux-mêmes (TextInput, NumberInput,
/// DateInput, …) ne sont **pas** dans cette story — ils seront créés par les
/// stories d'écrans qui en ont besoin (cascade Sprint 2+). `FormSection` est
/// un container léger qui regroupe ces enfants.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    this.hint,
    this.errors,
    required this.children,
    this.loading = false,
  });

  factory FormSection.fromJson(
    Map<String, dynamic> json, {
    required List<Widget> children,
  }) {
    final String? title = json['title'] as String?;
    if (title == null) {
      throw const FormatException("FormSection: 'title' requis");
    }
    return FormSection(
      title: title,
      hint: json['hint'] as String?,
      loading: json['loading'] as bool? ?? false,
      children: children,
    );
  }

  final String title;
  final String? hint;
  final List<FormFieldError>? errors;
  final List<Widget> children;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = <Widget>[
      Text(title, style: ScalarioTypography.overline),
      if (hint != null) ...<Widget>[
        const SizedBox(height: ScalarioSpacing.space1),
        Text(
          hint!,
          style: ScalarioTypography.caption,
        ),
      ],
      const SizedBox(height: ScalarioSpacing.space5),
      if (errors != null && errors!.isNotEmpty) ...<Widget>[
        AlertBanner(
          type: AlertType.warning,
          message: _composeErrorMessage(errors!),
        ),
        const SizedBox(height: ScalarioSpacing.space3),
      ],
      for (int i = 0; i < children.length; i++) ...<Widget>[
        children[i],
        if (i < children.length - 1)
          const SizedBox(height: ScalarioSpacing.space3),
      ],
    ];

    final Widget column = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ScalarioSpacing.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );

    if (!loading) return column;
    return IgnorePointer(
      child: Opacity(opacity: 0.5, child: column),
    );
  }

  static String _composeErrorMessage(List<FormFieldError> errors) {
    if (errors.length == 1) return errors.first.message;
    final List<String> bullets =
        errors.map((FormFieldError e) => '• ${e.message}').toList();
    return bullets.join('\n');
  }
}
