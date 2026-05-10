// Tests ThemeExtensions Scalario : couverture copyWith + lerp + parité
// light/dark (AC-17, AC-18, AC-19, AC-20).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/design_system/tokens/colors.dart';
import 'package:scalario/core/design_system/tokens/spacing.dart';
import 'package:scalario/core/theme/theme_extensions.dart';

void main() {
  group('ScalarioColorsExtension', () {
    test('light expose les 9 couleurs sémantiques métier', () {
      const ScalarioColorsExtension ext = ScalarioColorsExtension.light;

      expect(ext.synced, ScalarioColors.success500);
      expect(ext.syncing, ScalarioColors.primary500);
      expect(ext.offline, ScalarioColors.neutral500);
      expect(ext.syncError, ScalarioColors.warning500);
      expect(ext.conflict, ScalarioColors.warning700);
      expect(ext.surplus, ScalarioColors.primary500);
      expect(ext.critical, ScalarioColors.danger500);
      expect(ext.rupture, ScalarioColors.danger700);
      expect(ext.pendingCredit, ScalarioColors.warning700);
    });

    test('offline n\'est jamais rouge — décision UX P3', () {
      expect(
        ScalarioColorsExtension.light.offline,
        isNot(ScalarioColors.danger500),
      );
      expect(
        ScalarioColorsExtension.dark.offline,
        isNot(ScalarioColors.danger500),
      );
    });

    test('fromBrightness retourne dark pour Brightness.dark', () {
      expect(
        ScalarioColorsExtension.fromBrightness(Brightness.dark),
        same(ScalarioColorsExtension.dark),
      );
      expect(
        ScalarioColorsExtension.fromBrightness(Brightness.light),
        same(ScalarioColorsExtension.light),
      );
    });

    test('copyWith met à jour un seul champ', () {
      const ScalarioColorsExtension original = ScalarioColorsExtension.light;
      final ScalarioColorsExtension updated = original.copyWith(
        synced: ScalarioColors.primary700,
      );

      expect(updated.synced, ScalarioColors.primary700);
      expect(updated.syncing, original.syncing);
      expect(updated.offline, original.offline);
    });

    test('lerp retourne instance non-null à t=0.5', () {
      final ScalarioColorsExtension lerped =
          ScalarioColorsExtension.light.lerp(
        ScalarioColorsExtension.dark,
        0.5,
      );

      expect(lerped, isNotNull);
      expect(lerped.synced, isNotNull);
      expect(lerped.syncing, isNotNull);
    });

    test('lerp avec other null retourne this', () {
      final ScalarioColorsExtension lerped =
          ScalarioColorsExtension.light.lerp(null, 0.5);
      expect(lerped, same(ScalarioColorsExtension.light));
    });

    test('lerp t=0 retourne valeur source, t=1 retourne target', () {
      final ScalarioColorsExtension at0 =
          ScalarioColorsExtension.light.lerp(ScalarioColorsExtension.dark, 0);
      final ScalarioColorsExtension at1 =
          ScalarioColorsExtension.light.lerp(ScalarioColorsExtension.dark, 1);

      expect(at0.syncing, ScalarioColorsExtension.light.syncing);
      expect(at1.syncing, ScalarioColorsExtension.dark.syncing);
    });
  });

  group('ScalarioSpacingExtension', () {
    test('standard expose les 10 tokens spacing', () {
      const ScalarioSpacingExtension ext = ScalarioSpacingExtension.standard;
      expect(ext.space1, ScalarioSpacing.space1);
      expect(ext.space4, ScalarioSpacing.space4);
      expect(ext.space16, ScalarioSpacing.space16);
    });

    test('lerp interpole les doubles', () {
      const ScalarioSpacingExtension a = ScalarioSpacingExtension.standard;
      final ScalarioSpacingExtension b = a.copyWith(space4: 32);
      final ScalarioSpacingExtension lerped = a.lerp(b, 0.5);
      expect(lerped.space4, (16 + 32) / 2);
    });

    test('copyWith conserve les autres tokens', () {
      const ScalarioSpacingExtension a = ScalarioSpacingExtension.standard;
      final ScalarioSpacingExtension b = a.copyWith(space4: 99);
      expect(b.space4, 99);
      expect(b.space2, a.space2);
    });
  });

  group('ScalarioElevationExtension', () {
    test('standard expose e0..e4', () {
      const ScalarioElevationExtension ext =
          ScalarioElevationExtension.standard;
      expect(ext.e0, isEmpty);
      expect(ext.e1, hasLength(1));
      expect(ext.e4, hasLength(1));
    });

    test('lerp snap au target à t >= 0.5', () {
      const ScalarioElevationExtension a = ScalarioElevationExtension.standard;
      final ScalarioElevationExtension b = a.copyWith(e1: const <BoxShadow>[]);

      expect(a.lerp(b, 0.0).e1, hasLength(1));
      expect(a.lerp(b, 0.4).e1, hasLength(1));
      expect(a.lerp(b, 0.5).e1, isEmpty);
      expect(a.lerp(b, 1.0).e1, isEmpty);
    });

    test('fromBrightness retourne instance correcte', () {
      expect(
        ScalarioElevationExtension.fromBrightness(Brightness.dark),
        same(ScalarioElevationExtension.dark),
      );
      expect(
        ScalarioElevationExtension.fromBrightness(Brightness.light),
        same(ScalarioElevationExtension.standard),
      );
    });
  });
}
