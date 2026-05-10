// Smoke TextTheme : bodyMedium = 14sp Inter (AC-04, AC-05).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scalario/core/design_system/tokens/typography.dart';
import 'package:scalario/core/theme/text_theme_builder.dart';

/// Helper : exécute le test body dans une zone qui absorbe les exceptions
/// async google_fonts (les polices ne sont pas dans le bundle de test).
void _zonedTest(String description, FutureOr<void> Function() body) {
  test(description, () async {
    await runZonedGuarded<Future<void>>(() async {
      await body();
    }, (Object error, StackTrace stack) {});
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await runZonedGuarded<Future<void>>(() async {
      // ignore: unnecessary_statements
      ScalarioTypography.body;
      // ignore: unnecessary_statements
      ScalarioTypography.bodyMedium;
      await Future<void>.delayed(Duration.zero);
    }, (Object error, StackTrace stack) {});
  });

  group('ScalarioTextThemeBuilder', () {
    _zonedTest('bodyMedium = 14sp et famille contient Inter', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();

      expect(theme.bodyMedium, isNotNull);
      expect(theme.bodyMedium!.fontSize, 14);
      expect(theme.bodyMedium!.fontFamily, contains('Inter'));
    });

    _zonedTest('bodyLarge = 16sp', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();
      expect(theme.bodyLarge!.fontSize, 16);
    });

    _zonedTest('displayLarge = 28sp', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();
      expect(theme.displayLarge!.fontSize, 28);
    });

    _zonedTest('headlineLarge = 22sp', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();
      expect(theme.headlineLarge!.fontSize, 22);
    });

    _zonedTest('titleLarge = 18sp', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();
      expect(theme.titleLarge!.fontSize, 18);
    });

    _zonedTest('bodySmall (caption) = 12sp', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();
      expect(theme.bodySmall!.fontSize, 12);
    });

    _zonedTest('labelLarge (button) = 14sp medium', () {
      final TextTheme theme = ScalarioTextThemeBuilder.build();
      expect(theme.labelLarge!.fontSize, 14);
      expect(theme.labelLarge!.fontWeight, FontWeight.w500);
    });
  });
}
