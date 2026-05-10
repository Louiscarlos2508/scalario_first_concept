// Snapshot ColorScheme : vérifie que les slots clés du ColorScheme light
// et dark proviennent bien de ScalarioColors (AC-01, AC-02, AC-03).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/design_system/tokens/colors.dart';
import 'package:scalario/core/theme/color_scheme_builder.dart';

void main() {
  group('ScalarioColorSchemeBuilder.light', () {
    final ColorScheme scheme = ScalarioColorSchemeBuilder.light();

    test('brightness = light', () {
      expect(scheme.brightness, Brightness.light);
    });

    test('primary slots — primary500 / white', () {
      expect(scheme.primary, ScalarioColors.primary500);
      expect(scheme.onPrimary, ScalarioColors.white);
    });

    test('secondary slots — primary300 / textPrimary', () {
      expect(scheme.secondary, ScalarioColors.primary300);
      expect(scheme.onSecondary, ScalarioColors.textPrimary);
    });

    test('error slots — danger500 / white', () {
      expect(scheme.error, ScalarioColors.danger500);
      expect(scheme.onError, ScalarioColors.white);
    });

    test('surface slots — bgCard / textPrimary', () {
      expect(scheme.surface, ScalarioColors.bgCard);
      expect(scheme.onSurface, ScalarioColors.textPrimary);
    });

    test('surfaceContainerHighest — neutral100', () {
      expect(scheme.surfaceContainerHighest, ScalarioColors.neutral100);
    });

    test('outline — borderDefault', () {
      expect(scheme.outline, ScalarioColors.borderDefault);
    });
  });

  group('ScalarioColorSchemeBuilder.dark', () {
    final ColorScheme scheme = ScalarioColorSchemeBuilder.dark();

    test('brightness = dark', () {
      expect(scheme.brightness, Brightness.dark);
    });

    test('surface depuis bgCardDark', () {
      expect(scheme.surface, ScalarioColors.bgCardDark);
      expect(scheme.onSurface, ScalarioColors.textPrimaryDark);
    });

    test('outline depuis borderDefaultDark', () {
      expect(scheme.outline, ScalarioColors.borderDefaultDark);
    });

    test('error reste danger500 (sémantique stable)', () {
      expect(scheme.error, ScalarioColors.danger500);
    });
  });
}
