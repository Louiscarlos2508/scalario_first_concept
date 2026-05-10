import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/showcases/_showcase_app.dart';

void main() {
  group('ScalarioShowcaseApp', () {
    testWidgets('se monte sans exception', (WidgetTester tester) async {
      await tester.pumpWidget(const ScalarioShowcaseApp(
        title: 'Test',
        child: Text('contenu'),
      ));
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('contenu'), findsOneWidget);
    });

    testWidgets('toggle dark/light change ThemeMode', (WidgetTester tester) async {
      await tester.pumpWidget(const ScalarioShowcaseApp(
        title: 'Test',
        child: SizedBox(),
      ));

      // Mode initial = light — l'icône affiché est dark_mode_outlined.
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      // Tap le toggle.
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Mode dark — l'icône devient light_mode_outlined.
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    });
  });
}
