import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/sandbox/sandbox_error_view.dart';
import 'package:scalario/sandbox/sandbox_json_loader.dart';

void main() {
  testWidgets('SandboxErrorView renders path + position for parse error',
      (WidgetTester tester) async {
    const err = SandboxParseException(
      path: 'assets/sandbox/broken.json',
      message: 'Unexpected character',
      line: 4,
      column: 12,
      source: '{\n  "a": 1,\n  "b": 2,\n  bad,\n}',
    );
    bool retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SandboxErrorView(error: err, onRetry: () => retried = true),
        ),
      ),
    );
    expect(find.text('JSON invalide'), findsOneWidget);
    expect(find.textContaining('assets/sandbox/broken.json'), findsOneWidget);
    expect(find.textContaining('ligne 4'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    expect(retried, isTrue);
  });

  testWidgets('SandboxErrorView falls back to generic title for any error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SandboxErrorView(error: 'oups', onRetry: () {}),
        ),
      ),
    );
    expect(find.text('Erreur de rendu'), findsOneWidget);
  });
}
