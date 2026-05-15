/// STORY-012 — implémentation mobile + desktop natif (dart:io).
/// Phase 1 = stub ; STORY-035 livrera Drift natif + chemin
/// `getApplicationDocumentsDirectory`.
library;

import 'platform_storage.dart';

PlatformStorage createPlatformStorage() => const _IoStorage();

final class _IoStorage implements PlatformStorage {
  const _IoStorage();

  @override
  String get backend => 'io';

  @override
  String get location => 'app-documents (sqlite via Drift — STORY-035)';
}
