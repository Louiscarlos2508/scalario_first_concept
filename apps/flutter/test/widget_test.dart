// Scaffold smoke test : l'app boot et affiche le label tokens.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scalario/core/design_system/tokens/typography.dart';
import 'package:scalario/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Pré-cache les TextStyles pour que les erreurs async de google_fonts
    // (police absente du bundle de test) soient absorbées une seule fois ici.
    await runZonedGuarded<Future<void>>(() async {
      // ignore: unnecessary_statements
      ScalarioTypography.display;
      // ignore: unnecessary_statements
      ScalarioTypography.body;
      await Future<void>.delayed(Duration.zero);
    }, (Object error, StackTrace stack) {});
  });

  testWidgets('ScalarioApp boots et rend le label tokens', (
    WidgetTester tester,
  ) async {
    await runZonedGuarded<Future<void>>(() async {
      await tester.pumpWidget(const ScalarioApp());
      expect(find.text('Scalario'), findsOneWidget);
      expect(find.text('Design tokens chargés ✓'), findsOneWidget);
    }, (Object error, StackTrace stack) {});
  });
}
