// Snapshot test : compare les hex Dart aux hex extraits de la spec markdown.
//
// Source de vérité : `design-process/D-Design-System/tokens/colors.md`.
// Si la spec change → le test échoue → le dev doit mettre à jour `colors.dart`
// et inversement. Les deux côtés restent synchronisés.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/design_system/tokens/colors.dart';

const String _kSpecPath =
    '../../design-process/D-Design-System/tokens/colors.md';

/// Parse un hex `#1A3A5C` en `Color`.
Color _hex(String input) {
  final String trimmed = input.replaceAll('#', '').toUpperCase();
  final int value = int.parse(trimmed, radix: 16);
  return Color(0xFF000000 | value);
}

/// Lit la spec markdown et retourne la map `token → Color`.
/// Format markdown : ` | `color-primary-500` | `#2980B9` | … `.
Map<String, Color> _parseSpec(File md) {
  final Map<String, Color> map = <String, Color>{};
  final RegExp row =
      RegExp(r'\|\s*`([a-z0-9-]+)`\s*\|\s*`(#[0-9A-Fa-f]{6})`');
  for (final String line in md.readAsLinesSync()) {
    final RegExpMatch? m = row.firstMatch(line);
    if (m == null) continue;
    map[m.group(1)!] = _hex(m.group(2)!);
  }
  return map;
}

void main() {
  final File specFile = File(_kSpecPath);
  late final Map<String, Color> spec;

  setUpAll(() {
    expect(specFile.existsSync(), isTrue,
        reason: 'Spec markdown introuvable : ${specFile.absolute.path}. '
            'Vérifier que le test est lancé depuis apps/flutter/.');
    spec = _parseSpec(specFile);
    expect(spec.isNotEmpty, isTrue, reason: 'Aucun token parsé depuis la spec');
  });

  group('Palette primaire — sync spec → Dart', () {
    test('primary-50', () => expect(ScalarioColors.primary50, spec['color-primary-50']));
    test('primary-100', () => expect(ScalarioColors.primary100, spec['color-primary-100']));
    test('primary-300', () => expect(ScalarioColors.primary300, spec['color-primary-300']));
    test('primary-500', () => expect(ScalarioColors.primary500, spec['color-primary-500']));
    test('primary-700', () => expect(ScalarioColors.primary700, spec['color-primary-700']));
    test('primary-900', () => expect(ScalarioColors.primary900, spec['color-primary-900']));
  });

  group('Sémantiques — sync spec → Dart', () {
    test('success-100', () => expect(ScalarioColors.success100, spec['color-success-100']));
    test('success-500', () => expect(ScalarioColors.success500, spec['color-success-500']));
    test('success-700', () => expect(ScalarioColors.success700, spec['color-success-700']));

    test('warning-100', () => expect(ScalarioColors.warning100, spec['color-warning-100']));
    test('warning-500', () => expect(ScalarioColors.warning500, spec['color-warning-500']));
    test('warning-700', () => expect(ScalarioColors.warning700, spec['color-warning-700']));

    test('danger-100', () => expect(ScalarioColors.danger100, spec['color-danger-100']));
    test('danger-500', () => expect(ScalarioColors.danger500, spec['color-danger-500']));
    test('danger-700', () => expect(ScalarioColors.danger700, spec['color-danger-700']));

    test('info-100', () => expect(ScalarioColors.info100, spec['color-info-100']));
    test('info-500', () => expect(ScalarioColors.info500, spec['color-info-500']));
  });

  group('Neutres — sync spec → Dart', () {
    test('neutral-50', () => expect(ScalarioColors.neutral50, spec['color-neutral-50']));
    test('neutral-100', () => expect(ScalarioColors.neutral100, spec['color-neutral-100']));
    test('neutral-300', () => expect(ScalarioColors.neutral300, spec['color-neutral-300']));
    test('neutral-500', () => expect(ScalarioColors.neutral500, spec['color-neutral-500']));
    test('neutral-700', () => expect(ScalarioColors.neutral700, spec['color-neutral-700']));
    test('neutral-900', () => expect(ScalarioColors.neutral900, spec['color-neutral-900']));
    test('white', () => expect(ScalarioColors.white, spec['color-white']));
  });

  group('Tokens d\'application — alias cohérents', () {
    test('bgPage alias neutral50', () {
      expect(ScalarioColors.bgPage, ScalarioColors.neutral50);
    });

    test('bgCard alias white', () {
      expect(ScalarioColors.bgCard, ScalarioColors.white);
    });

    test('bgOverlay = rgba(0,0,0,0.5)', () {
      expect(ScalarioColors.bgOverlay, const Color(0x80000000));
    });

    test('textPrimary alias neutral900', () {
      expect(ScalarioColors.textPrimary, ScalarioColors.neutral900);
    });

    test('textSecondary alias neutral700', () {
      expect(ScalarioColors.textSecondary, ScalarioColors.neutral700);
    });

    test('textDisabled alias neutral500', () {
      expect(ScalarioColors.textDisabled, ScalarioColors.neutral500);
    });

    test('borderDefault alias neutral300', () {
      expect(ScalarioColors.borderDefault, ScalarioColors.neutral300);
    });

    test('borderFocus alias primary500', () {
      expect(ScalarioColors.borderFocus, ScalarioColors.primary500);
    });

    test('interactivePrimary alias primary500', () {
      expect(ScalarioColors.interactivePrimary, ScalarioColors.primary500);
    });

    test('interactiveDanger alias danger500', () {
      expect(ScalarioColors.interactiveDanger, ScalarioColors.danger500);
    });
  });

  group('Tokens dark-mode (placeholders STORY-002)', () {
    test('bgPageDark = neutral900', () {
      expect(ScalarioColors.bgPageDark, ScalarioColors.neutral900);
    });

    test('textPrimaryDark = neutral50', () {
      expect(ScalarioColors.textPrimaryDark, ScalarioColors.neutral50);
    });

    test('borderDefaultDark = neutral700', () {
      expect(ScalarioColors.borderDefaultDark, ScalarioColors.neutral700);
    });
  });
}
