import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/utils/conflict_resolution.dart';

void main() {
  group('shouldOverwrite', () {
    test('returns true when existing is null (no local copy)', () {
      expect(shouldOverwrite(null, DateTime(2024, 1, 1)), isTrue);
    });

    test('returns true when incoming is newer than existing', () {
      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2024, 1, 2);
      expect(shouldOverwrite(older, newer), isTrue);
    });

    test('returns false when incoming is older than existing', () {
      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2024, 1, 2);
      expect(shouldOverwrite(newer, older), isFalse);
    });

    test('returns false when incoming equals existing (same timestamp)', () {
      final ts = DateTime(2024, 6, 15, 12, 0, 0);
      expect(shouldOverwrite(ts, ts), isFalse);
    });

    test('returns false when incoming is null', () {
      expect(shouldOverwrite(DateTime(2024, 1, 1), null), isFalse);
    });
  });
}
