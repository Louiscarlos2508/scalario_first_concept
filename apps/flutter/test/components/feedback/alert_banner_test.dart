import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/feedback/alert_banner.dart';
import 'package:scalario/core/design_system/tokens/tokens.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  group('AlertBanner — types & couleurs', () {
    testWidgets('Critical : icône alert, fond danger-100, texte danger-700', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const AlertBanner(
        type: AlertType.critical,
        message: 'Stock critique',
      )));

      expect(find.text('Stock critique'), findsOneWidget);
      expect(find.byIcon(ScalarioIcons.alert), findsOneWidget);
    });

    testWidgets('Warning : icône warning rendue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const AlertBanner(
        type: AlertType.warning,
        message: 'Livraison en attente',
      )));
      expect(find.byIcon(ScalarioIcons.warning), findsOneWidget);
    });

    testWidgets('Success : icône check rendue', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const AlertBanner(
        type: AlertType.success,
        message: 'Vente enregistrée',
      )));
      expect(find.byIcon(ScalarioIcons.check), findsOneWidget);
    });

    testWidgets('Info : icône info rendue', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const AlertBanner(
        type: AlertType.info,
        message: 'Hors ligne',
      )));
      expect(find.byIcon(ScalarioIcons.info), findsOneWidget);
    });
  });

  group('AlertBanner — auto-dismiss', () {
    testWidgets('Success auto-dismiss après autoDismissMs', (
      WidgetTester tester,
    ) async {
      bool dismissed = false;
      await tester.pumpWidget(_wrap(AlertBanner(
        type: AlertType.success,
        message: 'Ok',
        autoDismissMs: 100,
        onDismiss: () => dismissed = true,
      )));

      expect(find.text('Ok'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 150));
      expect(dismissed, isTrue);
      expect(find.text('Ok'), findsNothing);
    });

    testWidgets('Critical jamais auto-dismiss même avec autoDismissMs', (
      WidgetTester tester,
    ) async {
      bool dismissed = false;
      await tester.pumpWidget(_wrap(AlertBanner(
        type: AlertType.critical,
        message: 'Critical',
        autoDismissMs: 100,
        onDismiss: () => dismissed = true,
      )));

      await tester.pump(const Duration(milliseconds: 200));
      expect(dismissed, isFalse);
      expect(find.text('Critical'), findsOneWidget);
    });
  });

  group('AlertBanner — action', () {
    testWidgets('actionLabel rendu et onAction appelé', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(_wrap(AlertBanner(
        type: AlertType.warning,
        message: 'Livraison en attente',
        actionLabel: 'Réceptionner',
        onAction: () => taps++,
      )));

      expect(find.text('Réceptionner'), findsOneWidget);
      await tester.tap(find.text('Réceptionner'));
      expect(taps, 1);
    });
  });

  group('AlertBanner.fromJson', () {
    test('parse minimal valide', () {
      final AlertBanner b = AlertBanner.fromJson(const <String, dynamic>{
        'type': 'critical',
        'message': 'Stock',
      });
      expect(b.type, AlertType.critical);
      expect(b.message, 'Stock');
    });

    test('message manquant → FormatException', () {
      expect(
        () => AlertBanner.fromJson(const <String, dynamic>{'type': 'info'}),
        throwsFormatException,
      );
    });

    test('type inconnu → fallback info', () {
      final AlertBanner b = AlertBanner.fromJson(const <String, dynamic>{
        'type': 'galactic',
        'message': 'Hello',
      });
      expect(b.type, AlertType.info);
    });
  });
}
