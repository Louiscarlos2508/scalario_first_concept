import '../canvas_layout/screen_config.dart';

/// Cache mémoire LRU `Map<screenId, ScreenConfig>` du [ScalarioCanvas].
///
/// STORY-008 — AC-10 : taille max configurable (défaut 20). Eviction LRU
/// stricte : la dernière entrée `get` ou `put` est la plus récente.
///
/// Implémentation : `LinkedHashMap` Dart (insertion-ordered). On retire +
/// réinsère sur `get` pour marquer "récemment utilisé".
final class ScreenCache {
  ScreenCache({this.maxSize = 20})
      : assert(maxSize > 0, 'maxSize must be > 0');

  final int maxSize;
  final Map<String, ScreenConfig> _entries = <String, ScreenConfig>{};

  int get length => _entries.length;

  ScreenConfig? get(String screenId) {
    final ScreenConfig? config = _entries.remove(screenId);
    if (config == null) return null;
    _entries[screenId] = config;
    return config;
  }

  void put(String screenId, ScreenConfig config) {
    _entries.remove(screenId);
    _entries[screenId] = config;
    while (_entries.length > maxSize) {
      _entries.remove(_entries.keys.first);
    }
  }

  bool contains(String screenId) => _entries.containsKey(screenId);

  void clear() => _entries.clear();

  /// Pour tests/debug : ordre LRU (du moins récent au plus récent).
  Iterable<String> get keysInLruOrder => _entries.keys;
}
