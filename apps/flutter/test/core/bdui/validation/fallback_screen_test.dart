import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/bdui/fallback_screen.dart';
import 'package:scalario/core/bdui/validation/validation_result.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

void main() {
  final errors = [
    ValidationError(path: '.screen', message: 'Champ obligatoire manquant', keyword: 'required'),
    ValidationError(path: '.zones', message: 'Type attendu : object', keyword: 'type'),
  ];

  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: ScalarioTheme.light(),
      home: child,
    );
  }

  testWidgets('shows French error message and retry button', (tester) async {
    await tester.pumpWidget(buildApp(
      FallbackScreen(
        errors: errors,
        onRetry: () {},
      ),
    ));

    expect(
      find.text("Cet écran n'a pas pu être chargé.\nNous avons enregistré le problème."),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('retry button triggers callback', (tester) async {
    bool retried = false;
    await tester.pumpWidget(buildApp(
      FallbackScreen(
        errors: errors,
        onRetry: () => retried = true,
      ),
    ));

    await tester.tap(find.text('Réessayer'));
    expect(retried, isTrue);
  });

  testWidgets('shows error details in debug mode', (tester) async {
    await tester.pumpWidget(buildApp(
      FallbackScreen(errors: errors, onRetry: () {}),
    ));

    expect(find.text('Détails techniques (debug)'), findsOneWidget);
    expect(find.text('.screen'), findsOneWidget);
    expect(find.text('.zones'), findsOneWidget);
  });

  testWidgets('shows error_id when provided', (tester) async {
    await tester.pumpWidget(buildApp(
      FallbackScreen(
        errors: errors,
        errorId: 'abc123def4567890',
      ),
    ));

    expect(find.textContaining('error_id: abc123def4567890'), findsOneWidget);
  });

  testWidgets('hides retry button when onRetry is null', (tester) async {
    await tester.pumpWidget(buildApp(
      FallbackScreen(errors: errors),
    ));

    expect(find.text('Réessayer'), findsNothing);
  });
}
