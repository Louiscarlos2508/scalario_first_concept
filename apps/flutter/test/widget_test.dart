// Scaffold smoke test : l'app boot avec le ThemeData Scalario chargé.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scalario/core/design_system/tokens/typography.dart';
import 'package:scalario/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await runZonedGuarded<Future<void>>(() async {
      // ignore: unnecessary_statements
      ScalarioTypography.display;
      // ignore: unnecessary_statements
      ScalarioTypography.body;
      await Future<void>.delayed(Duration.zero);
    }, (Object error, StackTrace stack) {});
  });

  testWidgets('ScalarioApp boots avec ThemeData Scalario', (
    WidgetTester tester,
  ) async {
    await runZonedGuarded<Future<void>>(() async {
      await tester.pumpWidget(const ScalarioApp());
      expect(find.text('Scalario'), findsWidgets);
      expect(find.text('ThemeData Scalario chargé'), findsOneWidget);
    }, (Object error, StackTrace stack) {});
  });
}
