import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/chart_bar.dart';
import 'package:scalario/core/design_system/tokens/tokens.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: SizedBox(width: 400, height: 300, child: child)),
    );

void main() {
  group('ChartBar — états', () {
    testWidgets('Normal : titre + barres rendues (CustomPaint)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const ChartBar(
        title: 'CA — 7 derniers jours',
        period: 'Cette semaine',
        unit: 'FCFA',
        data: <ChartDataPoint>[
          ChartDataPoint(label: 'L', value: 20),
          ChartDataPoint(label: 'M', value: 30),
          ChartDataPoint(label: 'M', value: 50),
          ChartDataPoint(label: 'J', value: 40),
        ],
      )));

      expect(find.text('CA — 7 derniers jours'), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Empty : message + icône chart', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const ChartBar(
        title: 'CA',
        data: <ChartDataPoint>[],
      )));

      expect(find.byIcon(ScalarioIcons.chart), findsOneWidget);
      expect(
        find.text('Pas de données pour cette période'),
        findsOneWidget,
      );
    });

    testWidgets('Loading : 5 barres shimmer', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(ChartBar.loading(title: 'CA')));
      // Pas de crash, et avancer le timer.
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CA'), findsOneWidget);
    });

    testWidgets('Error : message + retry CTA', (WidgetTester tester) async {
      int retries = 0;
      await tester.pumpWidget(_wrap(ChartBar.error(
        title: 'CA',
        message: 'Erreur de chargement',
        onRetry: () => retries++,
      )));

      expect(find.byIcon(ScalarioIcons.error), findsOneWidget);
      expect(find.text('Erreur de chargement'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);
    });

    testWidgets('onTap appelé quand l\'utilisateur tape une barre', (
      WidgetTester tester,
    ) async {
      ChartDataPoint? tapped;
      await tester.pumpWidget(_wrap(ChartBar(
        title: 'CA',
        data: const <ChartDataPoint>[
          ChartDataPoint(label: 'L', value: 10),
          ChartDataPoint(label: 'M', value: 20),
        ],
        onTap: (ChartDataPoint p) => tapped = p,
      )));

      // Tap au centre de l'aire dédiée du chart (clé stable).
      await tester.tap(
        find.byKey(const ValueKey<String>('chart-bar-tap-area')),
      );
      expect(tapped, isNotNull);
    });
  });

  group('ChartBar.fromJson', () {
    test('parse valide', () {
      final ChartBar c = ChartBar.fromJson(const <String, dynamic>{
        'title': 'CA',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'label': 'L', 'value': 10},
          <String, dynamic>{'label': 'M', 'value': 20},
        ],
        'unit': 'FCFA',
      });
      expect(c.title, 'CA');
      expect(c.data.length, 2);
      expect(c.data[0].label, 'L');
      expect(c.data[1].value, 20);
    });

    test('title manquant → title null (pas d\'exception)', () {
      final ChartBar c = ChartBar.fromJson(const <String, dynamic>{
        'data': <Map<String, dynamic>>[],
      });
      expect(c.title, isNull);
    });

    test('ChartDataPoint label manquant → FormatException', () {
      expect(
        () => ChartDataPoint.fromJson(const <String, dynamic>{'value': 1}),
        throwsFormatException,
      );
    });
  });
}
