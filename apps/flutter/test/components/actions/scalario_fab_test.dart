import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/actions/scalario_fab.dart';
import 'package:scalario/core/design_system/tokens/tokens.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

Widget _wrap(Widget fab) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(floatingActionButton: fab, body: const SizedBox.expand()),
    );

void main() {
  group('ScalarioFAB', () {
    testWidgets('Normal : icône rendue, onPressed appelé', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(ScalarioFAB(
        icon: ScalarioIcons.actionAdd,
        onPressed: () => taps++,
      )));

      expect(find.byIcon(ScalarioIcons.actionAdd), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(taps, 1);
    });

    testWidgets('Extended : icône + label', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(ScalarioFAB(
        icon: ScalarioIcons.actionAdd,
        label: 'Nouvelle vente',
        onPressed: () {},
      )));

      expect(find.text('Nouvelle vente'), findsOneWidget);
      expect(find.byIcon(ScalarioIcons.actionAdd), findsOneWidget);
    });

    testWidgets('Loading : spinner rendu, onPressed ignoré', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(ScalarioFAB(
        icon: ScalarioIcons.actionAdd,
        loading: true,
        onPressed: () => taps++,
      )));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(ScalarioIcons.actionAdd), findsNothing);

      // FAB désactivé pendant loading.
      final FloatingActionButton fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
      expect(taps, 0);
    });

    testWidgets('Disabled : opacité 0.5, FAB onPressed null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ScalarioFAB(
        icon: ScalarioIcons.actionAdd,
      )));

      expect(find.byType(Opacity), findsWidgets);
      final FloatingActionButton fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.onPressed, isNull);
    });
  });

  group('ScalarioFAB.fromJson', () {
    test('parse valide', () {
      final ScalarioFAB fab = ScalarioFAB.fromJson(const <String, dynamic>{
        'icon_code_point': 0xe145, // Icons.add code point
        'label': 'Vente',
      });
      expect(fab.label, 'Vente');
      expect(fab.icon.codePoint, 0xe145);
    });

    test('icon_code_point manquant → FormatException', () {
      expect(
        () => ScalarioFAB.fromJson(const <String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
