import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/lists/scalario_list_tile.dart';
import 'package:scalario/core/design_system/tokens/tokens.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('ScalarioListTile — états', () {
    testWidgets('Normal : title + subtitle rendus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ScalarioListTile(
        title: 'Tomates',
        subtitle: '42 kg vendus',
      )));

      expect(find.text('Tomates'), findsOneWidget);
      expect(find.text('42 kg vendus'), findsOneWidget);
    });

    testWidgets('Tappable : onTap appelé', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(ScalarioListTile(
        title: 'Igname',
        onTap: () => taps++,
      )));

      await tester.tap(find.byType(ListTile));
      expect(taps, 1);
    });

    testWidgets('Disabled : onTap pas appelé', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(ScalarioListTile(
        title: 'X',
        enabled: false,
        onTap: () => taps++,
      )));

      await tester.tap(find.byType(ListTile));
      expect(taps, 0);
    });

    testWidgets('Status : bordure gauche colorée présente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ScalarioListTile(
        title: 'Critical',
        status: ListTileStatus.danger,
      )));
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('Loading : shimmer rendu', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ScalarioListTile.loading()));
      // Ne crash pas et avance le timer.
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Empty : icône inbox + message centré', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(ScalarioListTile.empty('Aucun élément')));
      expect(find.text('Aucun élément'), findsOneWidget);
      expect(find.byIcon(ScalarioIcons.inbox), findsOneWidget);
    });

    testWidgets('Error : icône error + message rendus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(ScalarioListTile.error('Erreur')));
      expect(find.text('Erreur'), findsOneWidget);
      expect(find.byIcon(ScalarioIcons.error), findsOneWidget);
    });
  });

  group('ScalarioListTile.fromJson', () {
    test('parse valide', () {
      final ScalarioListTile tile =
          ScalarioListTile.fromJson(const <String, dynamic>{
        'title': 'Tomates',
        'subtitle': '42 kg',
        'status': 'success',
      });
      expect(tile.title, 'Tomates');
      expect(tile.status, ListTileStatus.success);
    });

    test('title manquant → FormatException', () {
      expect(
        () => ScalarioListTile.fromJson(const <String, dynamic>{}),
        throwsFormatException,
      );
    });
  });
}
