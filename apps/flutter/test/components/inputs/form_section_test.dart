import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/inputs/form_section.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('FormSection — états', () {
    testWidgets('Normal : titre + champs rendus', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const FormSection(
        title: 'IDENTITÉ',
        children: <Widget>[
          Text('Champ 1'),
          Text('Champ 2'),
        ],
      )));

      expect(find.text('IDENTITÉ'), findsOneWidget);
      expect(find.text('Champ 1'), findsOneWidget);
      expect(find.text('Champ 2'), findsOneWidget);
    });

    testWidgets('Avec hint : hint rendu sous le titre', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const FormSection(
        title: 'IDENTITÉ',
        hint: 'Renseignez nom et prénom',
        children: <Widget>[Text('Field')],
      )));
      expect(find.text('Renseignez nom et prénom'), findsOneWidget);
    });

    testWidgets('Errors : bandeau d\'erreur en haut', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const FormSection(
        title: 'IDENTITÉ',
        errors: <FormFieldError>[
          FormFieldError(fieldKey: 'name', message: 'Nom requis'),
          FormFieldError(fieldKey: 'phone', message: 'Téléphone invalide'),
        ],
        children: <Widget>[Text('Field')],
      )));

      // Les deux erreurs sont compilées en bullets dans un AlertBanner.
      expect(find.textContaining('Nom requis'), findsOneWidget);
      expect(find.textContaining('Téléphone invalide'), findsOneWidget);
    });

    testWidgets('Loading : IgnorePointer + opacité 0.5', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const FormSection(
        title: 'IDENTITÉ',
        loading: true,
        children: <Widget>[Text('Field')],
      )));

      // IgnorePointer apparaît plusieurs fois (Scaffold/MaterialApp en
      // ajoutent en interne) — on cible celui qui est ignoring=true.
      final Iterable<IgnorePointer> ignored = tester
          .widgetList<IgnorePointer>(find.byType(IgnorePointer))
          .where((IgnorePointer w) => w.ignoring);
      expect(ignored, isNotEmpty);
      final Opacity opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0.5);
    });
  });

  group('FormSection.fromJson', () {
    test('parse valide', () {
      final FormSection s = FormSection.fromJson(
        const <String, dynamic>{'title': 'IDENTITÉ', 'hint': 'Hint'},
        children: const <Widget>[Text('F')],
      );
      expect(s.title, 'IDENTITÉ');
      expect(s.hint, 'Hint');
    });

    test('title manquant → FormatException', () {
      expect(
        () => FormSection.fromJson(
          const <String, dynamic>{},
          children: const <Widget>[],
        ),
        throwsFormatException,
      );
    });
  });
}
