// STORY-012 — point d'entrée conditional import storage.
//
// `dart:io` (mobile + desktop natif) ↔ `dart:html` (web).
// Le compilateur tree-shake la branche non concernée.
//
// Phase 1 : stubs minimaux. Les implémentations réelles (Drift natif vs
// IndexedDB) sont livrées par STORY-035 (Offline Web FR-052).

export 'storage_stub.dart'
    if (dart.library.io) 'storage_io.dart'
    if (dart.library.html) 'storage_web.dart';
