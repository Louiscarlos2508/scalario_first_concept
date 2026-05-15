/// STORY-012 — implémentation web (dart:html / IndexedDB).
/// Phase 1 = stub ; STORY-035 livrera Drift web (sqlite WASM) + service
/// worker cache.
library;

import 'platform_storage.dart';

PlatformStorage createPlatformStorage() => const _WebStorage();

final class _WebStorage implements PlatformStorage {
  const _WebStorage();

  @override
  String get backend => 'web';

  @override
  String get location => 'IndexedDB (Drift web — STORY-035)';
}
