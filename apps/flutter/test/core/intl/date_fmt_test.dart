import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/intl/date_fmt.dart';

void main() {
  group('STORY-042 AC-09 — DateFmt', () {
    final tenMay2026 = DateTime(2026, 5, 10);

    test('yMd in fr-BF → 10/05/2026', () {
      expect(DateFmt.yMd(tenMay2026, 'fr-BF'), '10/05/2026');
    });

    test('yMd in fr-FR → 10/05/2026 (same EU pattern)', () {
      expect(DateFmt.yMd(tenMay2026, 'fr-FR'), '10/05/2026');
    });

    test('yMd in en-US → 5/10/2026 (US M/D order, no zero-pad)', () {
      expect(DateFmt.yMd(tenMay2026, 'en-US'), '5/10/2026');
    });

    test('hm in fr-BF uses 24h with zero-padding', () {
      expect(DateFmt.hm(DateTime(2026, 5, 10, 8, 5), 'fr-BF'), '08:05');
    });

    test('hm in en-US uses 12h with AM/PM', () {
      expect(DateFmt.hm(DateTime(2026, 5, 10, 8, 5), 'en-US'), '8:05 AM');
      expect(DateFmt.hm(DateTime(2026, 5, 10, 13, 5), 'en-US'), '1:05 PM');
      expect(DateFmt.hm(DateTime(2026, 5, 10, 0, 30), 'en-US'), '12:30 AM');
      expect(DateFmt.hm(DateTime(2026, 5, 10, 12, 0), 'en-US'), '12:00 PM');
    });

    test('relativePast — FR fallback', () {
      final now = DateTime(2026, 5, 24, 12, 0);
      expect(
        DateFmt.relativePast(now.subtract(const Duration(seconds: 30)), now: now),
        "à l'instant",
      );
      expect(
        DateFmt.relativePast(now.subtract(const Duration(minutes: 5)), now: now),
        'il y a 5 min',
      );
      expect(
        DateFmt.relativePast(now.subtract(const Duration(hours: 3)), now: now),
        'il y a 3 h',
      );
      expect(
        DateFmt.relativePast(now.subtract(const Duration(days: 2)), now: now),
        'il y a 2 j',
      );
    });

    test('relativePast — en locale', () {
      final now = DateTime(2026, 5, 24, 12, 0);
      expect(
        DateFmt.relativePast(
          now.subtract(const Duration(seconds: 30)),
          now: now,
          locale: 'en-US',
        ),
        'just now',
      );
      expect(
        DateFmt.relativePast(
          now.subtract(const Duration(minutes: 5)),
          now: now,
          locale: 'en-US',
        ),
        '5 min ago',
      );
    });
  });
}
