// Smoke tests : ScalarioTheme.light() et .dark() construisent un ThemeData
// Material 3 valide.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scalario/core/design_system/tokens/typography.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/core/theme/theme_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Pré-cache des TextStyles ScalarioTypography pour absorber l'exception
    // async google_fonts une seule fois (police absente du bundle de test).
    await runZonedGuarded<Future<void>>(() async {
      // ignore: unnecessary_statements
      ScalarioTypography.display;
      // ignore: unnecessary_statements
      ScalarioTypography.body;
      // ignore: unnecessary_statements
      ScalarioTypography.bodyMedium;
      await Future<void>.delayed(Duration.zero);
    }, (Object error, StackTrace stack) {});
  });

  group('ScalarioTheme', () {
    test('light() retourne un ThemeData non-null en Material 3', () async {
      late final ThemeData theme;
      await runZonedGuarded<Future<void>>(() async {
        theme = ScalarioTheme.light();
      }, (Object error, StackTrace stack) {});

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark() retourne un ThemeData non-null en Material 3', () async {
      late final ThemeData theme;
      await runZonedGuarded<Future<void>>(() async {
        theme = ScalarioTheme.dark();
      }, (Object error, StackTrace stack) {});

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('light et dark exposent les mêmes types d\'extensions (parité)',
        () async {
      late final ThemeData light;
      late final ThemeData dark;
      await runZonedGuarded<Future<void>>(() async {
        light = ScalarioTheme.light();
        dark = ScalarioTheme.dark();
      }, (Object error, StackTrace stack) {});

      final Set<Object> lightKeys = light.extensions.keys.toSet();
      final Set<Object> darkKeys = dark.extensions.keys.toSet();

      expect(lightKeys, equals(darkKeys));
      expect(
        lightKeys,
        containsAll(<Type>[
          ScalarioColorsExtension,
          ScalarioSpacingExtension,
          ScalarioElevationExtension,
        ]),
      );
    });

    test('light et dark exposent tous les component themes critiques',
        () async {
      late final ThemeData light;
      late final ThemeData dark;
      await runZonedGuarded<Future<void>>(() async {
        light = ScalarioTheme.light();
        dark = ScalarioTheme.dark();
      }, (Object error, StackTrace stack) {});

      for (final ThemeData theme in <ThemeData>[light, dark]) {
        // Boutons
        expect(theme.filledButtonTheme.style, isNotNull);
        expect(theme.outlinedButtonTheme.style, isNotNull);
        expect(theme.textButtonTheme.style, isNotNull);
        expect(theme.elevatedButtonTheme.style, isNotNull);
        // Surfaces
        expect(theme.cardTheme, isNotNull);
        expect(theme.dialogTheme, isNotNull);
        expect(theme.appBarTheme, isNotNull);
        expect(theme.bottomSheetTheme, isNotNull);
        // Inputs
        expect(theme.inputDecorationTheme, isNotNull);
        // Data
        expect(theme.dataTableTheme, isNotNull);
        expect(theme.bottomNavigationBarTheme, isNotNull);
        expect(theme.navigationBarTheme, isNotNull);
        expect(theme.floatingActionButtonTheme, isNotNull);
        expect(theme.chipTheme, isNotNull);
        expect(theme.listTileTheme, isNotNull);
        // Feedback
        expect(theme.badgeTheme, isNotNull);
        expect(theme.dividerTheme, isNotNull);
        expect(theme.iconTheme, isNotNull);
        expect(theme.snackBarTheme, isNotNull);
        expect(theme.tooltipTheme, isNotNull);
      }
    });
  });
}
