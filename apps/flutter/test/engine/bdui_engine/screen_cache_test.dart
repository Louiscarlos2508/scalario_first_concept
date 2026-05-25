import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas/screen_cache.dart';
import 'package:scalario/engine/canvas_layout/screen_config.dart';

ScreenConfig _stub(String id) => ScreenConfig(
      screen: id,
      schemaVersion: '1.0.0',
      layout: 'dashboard',
    );

void main() {
  group('ScreenCache', () {
    test('miss returns null, hit returns config', () {
      final ScreenCache cache = ScreenCache(maxSize: 3);
      expect(cache.get('a'), isNull);
      cache.put('a', _stub('a'));
      expect(cache.get('a')?.screen, 'a');
      expect(cache.contains('a'), isTrue);
    });

    test('LRU eviction when exceeding maxSize', () {
      final ScreenCache cache = ScreenCache(maxSize: 3);
      cache.put('a', _stub('a'));
      cache.put('b', _stub('b'));
      cache.put('c', _stub('c'));
      cache.put('d', _stub('d')); // evicts a
      expect(cache.contains('a'), isFalse);
      expect(cache.contains('b'), isTrue);
      expect(cache.contains('c'), isTrue);
      expect(cache.contains('d'), isTrue);
      expect(cache.length, 3);
    });

    test('get marks entry as most recently used', () {
      final ScreenCache cache = ScreenCache(maxSize: 3);
      cache.put('a', _stub('a'));
      cache.put('b', _stub('b'));
      cache.put('c', _stub('c'));
      // Touch 'a' so it becomes the most recent.
      cache.get('a');
      cache.put('d', _stub('d')); // should evict 'b' (oldest), not 'a'.
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('b'), isFalse);
      expect(cache.contains('c'), isTrue);
      expect(cache.contains('d'), isTrue);
    });

    test('put refreshes existing entry without eviction', () {
      final ScreenCache cache = ScreenCache(maxSize: 2);
      cache.put('a', _stub('a'));
      cache.put('b', _stub('b'));
      cache.put('a', _stub('a')); // refresh, no eviction.
      expect(cache.length, 2);
      expect(cache.contains('a'), isTrue);
      expect(cache.contains('b'), isTrue);
    });

    test('clear empties the cache', () {
      final ScreenCache cache = ScreenCache();
      cache.put('a', _stub('a'));
      cache.clear();
      expect(cache.length, 0);
      expect(cache.contains('a'), isFalse);
    });

    test('asserts maxSize > 0', () {
      expect(() => ScreenCache(maxSize: 0), throwsA(isA<AssertionError>()));
    });
  });
}
