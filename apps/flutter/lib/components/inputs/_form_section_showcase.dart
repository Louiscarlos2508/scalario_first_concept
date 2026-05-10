// Run (standalone):  flutter run --target=lib/components/inputs/_form_section_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/03-inputs.md (FormSection)

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'form_section.dart';

PreviewThemeData scalarioFormSectionThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioFormSectionWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

// Champs stand-in Material 3 bruts (TextInput Scalario = Sprint 2+).
List<Widget> get _placeholderFields => <Widget>[
      const TextField(decoration: InputDecoration(labelText: 'Produit')),
      const TextField(decoration: InputDecoration(labelText: 'Quantité')),
      const TextField(decoration: InputDecoration(labelText: 'Prix unitaire')),
    ];

@Preview(name: 'Normal', theme: scalarioFormSectionThemes, wrapper: scalarioFormSectionWrap)
Widget previewFormSectionNormal() => FormSection(
      title: 'DÉTAILS ARTICLE',
      children: _placeholderFields,
    );

@Preview(name: 'Avec hint', theme: scalarioFormSectionThemes, wrapper: scalarioFormSectionWrap)
Widget previewFormSectionHint() => FormSection(
      title: 'INFORMATIONS BOUTIQUE',
      hint: 'Ces informations apparaissent sur les reçus clients.',
      children: _placeholderFields,
    );

@Preview(name: 'Avec erreurs inline', theme: scalarioFormSectionThemes, wrapper: scalarioFormSectionWrap)
Widget previewFormSectionErrors() => FormSection(
      title: 'STOCK ENTRÉE',
      errors: const <FormFieldError>[
        FormFieldError(fieldKey: 'quantity', message: 'La quantité doit être supérieure à 0.'),
        FormFieldError(fieldKey: 'price', message: 'Le prix unitaire est requis.'),
      ],
      children: _placeholderFields,
    );

@Preview(name: 'Loading', theme: scalarioFormSectionThemes, wrapper: scalarioFormSectionWrap)
Widget previewFormSectionLoading() => FormSection(
      title: 'CHARGEMENT…',
      loading: true,
      children: _placeholderFields,
    );

class _FormSectionShowcase extends StatelessWidget {
  const _FormSectionShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            previewFormSectionNormal(),
            const SizedBox(height: ScalarioSpacing.space6),
            previewFormSectionHint(),
            const SizedBox(height: ScalarioSpacing.space6),
            previewFormSectionErrors(),
            const SizedBox(height: ScalarioSpacing.space6),
            previewFormSectionLoading(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'FormSection Showcase',
      child: _FormSectionShowcase(),
    ));
