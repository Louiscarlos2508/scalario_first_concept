import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/kpi_card.dart';
import 'package:scalario/core/design_system/tokens/tokens.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('KPICard — états visuels', () {
    testWidgets('Nominal : label + valeur + unit + delta rendus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const KPICard(
          label: 'CA du jour',
          value: '47 500',
          unit: 'FCFA',
          delta: '+12% vs hier',
        )),
      );

      expect(find.text('CA du jour'), findsOneWidget);
      expect(find.text('47 500'), findsOneWidget);
      expect(find.text('FCFA'), findsOneWidget);
      expect(find.text('+12% vs hier'), findsOneWidget);
    });

    testWidgets('Critical : icône absente, fond danger, valeur danger500', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const KPICard(
          label: 'Stock critique',
          value: '3',
          status: KpiStatus.critical,
        )),
      );

      // La valeur est rendue.
      expect(find.text('3'), findsOneWidget);

      // Le container possède une bordure gauche danger-500.
      final Finder containerFinder = find
          .ancestor(
            of: find.text('3'),
            matching: find.byType(Container),
          )
          .first;
      final Container container = tester.widget<Container>(containerFinder);
      final BoxDecoration deco = container.decoration! as BoxDecoration;
      expect(deco.color, ScalarioColors.danger100);
      expect(deco.border, isA<Border>());
    });

    testWidgets('Warning : fond warning-100, bordure warning-500', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const KPICard(
          label: 'Stock bas',
          value: '12',
          status: KpiStatus.warning,
        )),
      );

      final Container container = tester.widget<Container>(
        find
            .ancestor(of: find.text('12'), matching: find.byType(Container))
            .first,
      );
      final BoxDecoration deco = container.decoration! as BoxDecoration;
      expect(deco.color, ScalarioColors.warning100);
    });

    testWidgets('Tappable : chevron rendu et onTap appelé', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _wrap(KPICard(
          label: 'CA',
          value: '47 500',
          onTap: () => taps++,
        )),
      );

      expect(find.byIcon(ScalarioIcons.chevronRight), findsOneWidget);
      await tester.tap(find.byType(KPICard));
      expect(taps, 1);
    });

    testWidgets('Loading : shimmer rendu, valeur absente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(KPICard.loading(label: 'CA')));
      expect(find.text('CA'), findsOneWidget);
      // Skeleton rendu — pas de texte de valeur.
      expect(find.text('47 500'), findsNothing);
      // Avancer le timer pour ne pas laisser le shimmer en boucle pendant le teardown.
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Empty : valeur "—" rendue', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(KPICard.empty('Stock')));
      expect(find.text('Stock'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('Error : icône error + message rendus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(KPICard.error(
          label: 'Connexion',
          message: 'Backend indisponible',
        )),
      );
      expect(find.byIcon(ScalarioIcons.error), findsOneWidget);
      expect(find.text('Backend indisponible'), findsOneWidget);
    });
  });

  group('KPICard.fromJson', () {
    test('parse valide → widget instancié', () {
      final KPICard card = KPICard.fromJson(const <String, dynamic>{
        'label': 'CA',
        'value': '47 500',
        'unit': 'FCFA',
        'delta': '+12%',
        'delta_positive': true,
        'status': 'critical',
      });
      expect(card.label, 'CA');
      expect(card.value, '47 500');
      expect(card.status, KpiStatus.critical);
    });

    test('label manquant → FormatException', () {
      expect(
        () => KPICard.fromJson(const <String, dynamic>{'value': '0'}),
        throwsFormatException,
      );
    });

    test('status inconnu → fallback nominal', () {
      final KPICard card = KPICard.fromJson(const <String, dynamic>{
        'label': 'X',
        'value': '0',
        'status': 'martian',
      });
      expect(card.status, KpiStatus.nominal);
    });
  });
}
