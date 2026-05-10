// Smoke tests typographie : chaque style produit un TextStyle non-null avec
// la bonne size + weight conformes à la spec markdown
// (`design-process/D-Design-System/tokens/typography.md`).
//
// google_fonts ne peut pas charger ses polices dans `flutter test` (pas de
// réseau, pas de bundle d'assets). On vérifie uniquement les *métriques* du
// TextStyle (size, weight, height) qui sont déterminées synchrones. Les
// erreurs HTTP asynchrones de google_fonts sont capturées via
// `PlatformDispatcher.onError`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scalario/core/design_system/tokens/typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // google_fonts émet des erreurs async quand ni asset ni réseau ne servent
    // la police. On vérifie les métriques sync — pas le rendu. On absorbe ces
    // erreurs dans une zone dédiée pour qu'elles ne fassent pas échouer le
    // test runner. Astuce : on **pré-déclenche** ici tous les `static final`
    // de ScalarioTypography pour que chaque variante (Inter w400/w500/w600/
    // w700, Roboto Mono w400/w500/w700) ne soit instanciée qu'une fois —
    // suivi des `setUp` propre à chaque test qui n'a plus à toucher google_fonts.
    await runZonedGuarded<Future<void>>(() async {
      final List<TextStyle> primed = <TextStyle>[
        ScalarioTypography.display,
        ScalarioTypography.headline,
        ScalarioTypography.title,
        ScalarioTypography.bodyLg,
        ScalarioTypography.body,
        ScalarioTypography.bodyMedium,
        ScalarioTypography.caption,
        ScalarioTypography.captionMedium,
        ScalarioTypography.overline,
        ScalarioTypography.displayMono,
        ScalarioTypography.bodyMono,
        ScalarioTypography.bodyMediumMono,
        ScalarioTypography.captionMono,
      ];
      expect(primed.every((TextStyle s) => s.fontSize != null), isTrue);
      await Future<void>.delayed(Duration.zero);
    }, (Object error, StackTrace stack) {
      // Erreurs google_fonts attendues — silence.
    });
  });

  group('Échelle typographique — 9 styles', () {
    test('display — 28sp / w700 / 1.2', () {
      final TextStyle s = ScalarioTypography.display;
      expect(s.fontSize, 28);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.height, 1.2);
    });

    test('headline — 22sp / w600 / 1.3', () {
      final TextStyle s = ScalarioTypography.headline;
      expect(s.fontSize, 22);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.height, 1.3);
    });

    test('title — 18sp / w600 / 1.3', () {
      final TextStyle s = ScalarioTypography.title;
      expect(s.fontSize, 18);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.height, 1.3);
    });

    test('bodyLg — 16sp / w400 / 1.5', () {
      final TextStyle s = ScalarioTypography.bodyLg;
      expect(s.fontSize, 16);
      expect(s.fontWeight, FontWeight.w400);
      expect(s.height, 1.5);
    });

    test('body — 14sp / w400 / 1.5', () {
      final TextStyle s = ScalarioTypography.body;
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w400);
      expect(s.height, 1.5);
    });

    test('bodyMedium — 14sp / w500 / 1.5', () {
      final TextStyle s = ScalarioTypography.bodyMedium;
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.height, 1.5);
    });

    test('caption — 12sp / w400 / 1.4', () {
      final TextStyle s = ScalarioTypography.caption;
      expect(s.fontSize, 12);
      expect(s.fontWeight, FontWeight.w400);
      expect(s.height, 1.4);
    });

    test('captionMedium — 12sp / w500 / 1.4', () {
      final TextStyle s = ScalarioTypography.captionMedium;
      expect(s.fontSize, 12);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.height, 1.4);
    });

    test('overline — 11sp / w500 / 1.2', () {
      final TextStyle s = ScalarioTypography.overline;
      expect(s.fontSize, 11);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.height, 1.2);
    });
  });

  group('Variantes Mono — Roboto Mono pour chiffres temps réel', () {
    test('displayMono — same metrics as display', () {
      final TextStyle s = ScalarioTypography.displayMono;
      expect(s.fontSize, 28);
      expect(s.fontWeight, FontWeight.w700);
    });

    test('bodyMono — same metrics as body', () {
      final TextStyle s = ScalarioTypography.bodyMono;
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w400);
    });

    test('bodyMediumMono — w500', () {
      final TextStyle s = ScalarioTypography.bodyMediumMono;
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w500);
    });

    test('captionMono — 12sp / w400', () {
      final TextStyle s = ScalarioTypography.captionMono;
      expect(s.fontSize, 12);
      expect(s.fontWeight, FontWeight.w400);
    });
  });

  group('Tokens d\'application — alias cohérents', () {
    test('fontKpiValue → displayMono (anti-layout-shift)', () {
      expect(ScalarioTypography.fontKpiValue.fontSize,
          ScalarioTypography.displayMono.fontSize);
      expect(ScalarioTypography.fontKpiValue.fontWeight,
          ScalarioTypography.displayMono.fontWeight);
    });

    test('fontKpiLabel → caption', () {
      expect(ScalarioTypography.fontKpiLabel.fontSize,
          ScalarioTypography.caption.fontSize);
    });

    test('fontKpiDelta → captionMedium', () {
      expect(ScalarioTypography.fontKpiDelta.fontWeight,
          ScalarioTypography.captionMedium.fontWeight);
    });

    test('fontButton → bodyMedium', () {
      expect(ScalarioTypography.fontButton.fontSize,
          ScalarioTypography.bodyMedium.fontSize);
      expect(ScalarioTypography.fontButton.fontWeight,
          ScalarioTypography.bodyMedium.fontWeight);
    });

    test('fontInputLabel → captionMedium', () {
      expect(ScalarioTypography.fontInputLabel.fontWeight,
          ScalarioTypography.captionMedium.fontWeight);
    });

    test('fontInputValue → body', () {
      expect(ScalarioTypography.fontInputValue.fontSize,
          ScalarioTypography.body.fontSize);
    });

    test('fontInputHint → caption', () {
      expect(ScalarioTypography.fontInputHint.fontSize,
          ScalarioTypography.caption.fontSize);
    });

    test('fontBannerText → bodyMedium', () {
      expect(ScalarioTypography.fontBannerText.fontWeight,
          ScalarioTypography.bodyMedium.fontWeight);
    });

    test('fontListPrimary → bodyMedium', () {
      expect(ScalarioTypography.fontListPrimary.fontWeight,
          ScalarioTypography.bodyMedium.fontWeight);
    });

    test('fontListSecondary → caption', () {
      expect(ScalarioTypography.fontListSecondary.fontSize,
          ScalarioTypography.caption.fontSize);
    });

    test('fontSectionTitle → title', () {
      expect(ScalarioTypography.fontSectionTitle.fontSize,
          ScalarioTypography.title.fontSize);
    });

    test('fontPageTitle → headline', () {
      expect(ScalarioTypography.fontPageTitle.fontSize,
          ScalarioTypography.headline.fontSize);
    });
  });

  test('Toutes les références fonts (Inter / Roboto Mono) sont non-null', () {
    expect(ScalarioTypography.interFamily, 'Inter');
    expect(ScalarioTypography.robotoMonoFamily, 'Roboto Mono');
    expect(ScalarioTypography.fallback, contains('system-ui'));
  });
}
