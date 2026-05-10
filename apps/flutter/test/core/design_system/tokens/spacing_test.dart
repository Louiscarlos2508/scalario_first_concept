// Snapshot test : compare les valeurs spacing/radius/elevation Dart aux
// valeurs extraites de la spec markdown.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/design_system/tokens/spacing.dart';

const String _kSpecPath =
    '../../design-process/D-Design-System/tokens/spacing.md';

/// Parse les rangées markdown pour extraire `space-N → Npx`.
Map<String, double> _parseNumericTokens(File md) {
  final Map<String, double> map = <String, double>{};
  // Rangées du type ` | `space-1` | 4px | … `.
  final RegExp row =
      RegExp(r'\|\s*`([a-z0-9-]+)`\s*\|\s*(\d+)\s*px');
  for (final String line in md.readAsLinesSync()) {
    final RegExpMatch? m = row.firstMatch(line);
    if (m == null) continue;
    map[m.group(1)!] = double.parse(m.group(2)!);
  }
  return map;
}

void main() {
  final File specFile = File(_kSpecPath);
  late final Map<String, double> spec;

  setUpAll(() {
    expect(specFile.existsSync(), isTrue,
        reason: 'Spec markdown introuvable : ${specFile.absolute.path}');
    spec = _parseNumericTokens(specFile);
    expect(spec.isNotEmpty, isTrue);
  });

  group('Grille 4px — sync spec → Dart', () {
    test('space-1', () => expect(ScalarioSpacing.space1, spec['space-1']));
    test('space-2', () => expect(ScalarioSpacing.space2, spec['space-2']));
    test('space-3', () => expect(ScalarioSpacing.space3, spec['space-3']));
    test('space-4', () => expect(ScalarioSpacing.space4, spec['space-4']));
    test('space-5', () => expect(ScalarioSpacing.space5, spec['space-5']));
    test('space-6', () => expect(ScalarioSpacing.space6, spec['space-6']));
    test('space-8', () => expect(ScalarioSpacing.space8, spec['space-8']));
    test('space-10', () => expect(ScalarioSpacing.space10, spec['space-10']));
    test('space-12', () => expect(ScalarioSpacing.space12, spec['space-12']));
    test('space-16', () => expect(ScalarioSpacing.space16, spec['space-16']));
  });

  group('Border radius — sync spec → Dart', () {
    test('radius-sm', () => expect(ScalarioRadius.sm, spec['radius-sm']));
    test('radius-md', () => expect(ScalarioRadius.md, spec['radius-md']));
    test('radius-lg', () => expect(ScalarioRadius.lg, spec['radius-lg']));
    test('radius-xl', () => expect(ScalarioRadius.xl, spec['radius-xl']));

    test('radius-full = 999 (pill)', () {
      expect(ScalarioRadius.full, 999);
    });
  });

  group('Elevation — chaque token retourne List<BoxShadow>', () {
    test('e0 = aucun shadow', () {
      expect(ScalarioElevation.e0, isEmpty);
    });

    test('e1 — 1 shadow, blur 3, alpha ~0.08', () {
      expect(ScalarioElevation.e1, hasLength(1));
      final BoxShadow s = ScalarioElevation.e1.first;
      expect(s.blurRadius, 3);
      expect(s.offset, const Offset(0, 1));
      // 0.08 * 255 ≈ 20 = 0x14
      expect((s.color.a * 255).round(), 0x14);
    });

    test('e2 — 1 shadow, blur 8, alpha ~0.12', () {
      expect(ScalarioElevation.e2, hasLength(1));
      final BoxShadow s = ScalarioElevation.e2.first;
      expect(s.blurRadius, 8);
      expect(s.offset, const Offset(0, 2));
      // 0.12 * 255 ≈ 31 = 0x1F
      expect((s.color.a * 255).round(), 0x1F);
    });

    test('e3 — 1 shadow, blur 16, alpha ~0.16', () {
      final BoxShadow s = ScalarioElevation.e3.first;
      expect(s.blurRadius, 16);
      expect(s.offset, const Offset(0, 4));
      expect((s.color.a * 255).round(), 0x29);
    });

    test('e4 — 1 shadow, blur 24, alpha ~0.20', () {
      final BoxShadow s = ScalarioElevation.e4.first;
      expect(s.blurRadius, 24);
      expect(s.offset, const Offset(0, 8));
      expect((s.color.a * 255).round(), 0x33);
    });
  });

  group('Layout tokens', () {
    test('mobilePagePaddingH = 16', () {
      expect(ScalarioLayout.mobilePagePaddingH, 16);
    });

    test('mobilePagePaddingTop = 16', () {
      expect(ScalarioLayout.mobilePagePaddingTop, 16);
    });

    test('webMaxWidth = 1200', () {
      expect(ScalarioLayout.webMaxWidth, 1200);
    });

    test('webPagePaddingH = 32', () {
      expect(ScalarioLayout.webPagePaddingH, 32);
    });

    test('sidebarWidth = 240', () {
      expect(ScalarioLayout.sidebarWidth, 240);
    });

    test('bottomNavHeight = 56', () {
      expect(ScalarioLayout.bottomNavHeight, 56);
    });

    test('syncBarHeight = 28', () {
      expect(ScalarioLayout.syncBarHeight, 28);
    });
  });
}
