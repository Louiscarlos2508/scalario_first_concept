import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_layout/breakpoints.dart';

void main() {
  group('BreakpointResolver.fromWidth', () {
    // Boundaries exactes — AC-26
    test('599 → mobile', () {
      expect(BreakpointResolver.fromWidth(599), Breakpoint.mobile);
    });

    test('600 → tablet', () {
      expect(BreakpointResolver.fromWidth(600), Breakpoint.tablet);
    });

    test('1024 → tablet', () {
      expect(BreakpointResolver.fromWidth(1024), Breakpoint.tablet);
    });

    test('1025 → desktop', () {
      expect(BreakpointResolver.fromWidth(1025), Breakpoint.desktop);
    });

    // Valeurs internes à chaque range
    test('360 → mobile (Snapdragon 680 typique)', () {
      expect(BreakpointResolver.fromWidth(360), Breakpoint.mobile);
    });

    test('0 → mobile', () {
      expect(BreakpointResolver.fromWidth(0), Breakpoint.mobile);
    });

    test('800 → tablet', () {
      expect(BreakpointResolver.fromWidth(800), Breakpoint.tablet);
    });

    test('1280 → desktop', () {
      expect(BreakpointResolver.fromWidth(1280), Breakpoint.desktop);
    });

    test('2560 → desktop (4K, pas de breakpoint ultra-wide Phase 1)', () {
      expect(BreakpointResolver.fromWidth(2560), Breakpoint.desktop);
    });
  });

  group('BreakpointResolver.fromConstraints', () {
    test('lit constraints.maxWidth correctement', () {
      const BoxConstraints c = BoxConstraints(maxWidth: 599);
      expect(BreakpointResolver.fromConstraints(c), Breakpoint.mobile);
    });

    test('600dp → tablet', () {
      const BoxConstraints c = BoxConstraints(maxWidth: 600);
      expect(BreakpointResolver.fromConstraints(c), Breakpoint.tablet);
    });

    test('1440dp → desktop', () {
      const BoxConstraints c = BoxConstraints(maxWidth: 1440);
      expect(BreakpointResolver.fromConstraints(c), Breakpoint.desktop);
    });
  });

  group('Breakpoint enum', () {
    test('contient exactement 3 valeurs (AC-01)', () {
      expect(Breakpoint.values.length, 3);
    });

    test('valeurs : mobile, tablet, desktop', () {
      expect(Breakpoint.values, <Breakpoint>[
        Breakpoint.mobile,
        Breakpoint.tablet,
        Breakpoint.desktop,
      ]);
    });
  });
}
