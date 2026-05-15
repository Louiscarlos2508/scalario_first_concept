// STORY-009 — Sandbox dev-only.
//
// Détecte la modification d'un fichier sandbox et notifie l'écran via un
// callback. Trois variantes :
//
//  - [NativeFileWatcher]   → `dart:io File.watch` (mobile/desktop). AC-08.
//  - [PollingFileWatcher]  → fallback Web ou plateformes sans inotify. AC-09.
//  - [NoopFileWatcher]     → tests / mode bundle.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'sandbox_file_source_stub.dart'
    if (dart.library.io) 'sandbox_file_source_io.dart' as fs;

typedef SandboxWatchCallback = void Function();

/// Stratégie générique. `start` retourne un handle dispose-able.
abstract class SandboxFileWatcher {
  Future<void> start(String path, SandboxWatchCallback onChange);
  Future<void> stop();
}

/// Tests / mode bundle : ne déclenche jamais.
class NoopFileWatcher implements SandboxFileWatcher {
  const NoopFileWatcher();
  @override
  Future<void> start(String path, SandboxWatchCallback onChange) async {}
  @override
  Future<void> stop() async {}
}

/// `dart:io File.watch` — utilisé sur Linux/macOS/Windows/iOS sim/Android sim
/// quand un chemin filesystem est disponible (mode [FileJsonSource]).
class NativeFileWatcher implements SandboxFileWatcher {
  NativeFileWatcher({this.debounceMs = 100});
  final int debounceMs;
  StreamSubscription<dynamic>? _sub;
  Timer? _debounce;

  @override
  Future<void> start(String path, SandboxWatchCallback onChange) async {
    if (kIsWeb) {
      throw UnsupportedError('NativeFileWatcher indisponible sur Web');
    }
    await stop();
    try {
      _sub = fs.watchFile(path).listen(
        (_) {
          _debounce?.cancel();
          _debounce = Timer(Duration(milliseconds: debounceMs), onChange);
        },
        onError: (Object e, StackTrace st) {
          if (kDebugMode) {
            debugPrint('NativeFileWatcher error on $path: $e');
          }
        },
      );
    } on UnsupportedError {
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _debounce?.cancel();
    _debounce = null;
    await _sub?.cancel();
    _sub = null;
  }
}

/// Polling 1.5s — fallback Web (AC-09) ou plateforme sans inotify. Lit le
/// contenu et appelle [onChange] si la signature change.
class PollingFileWatcher implements SandboxFileWatcher {
  PollingFileWatcher({
    required this.readSignature,
    this.pollInterval = const Duration(milliseconds: 1500),
  });

  /// Renvoie un hash/contenu/lastModified suffisamment discriminant.
  final Future<String> Function() readSignature;
  final Duration pollInterval;

  Timer? _timer;
  String? _last;

  @override
  Future<void> start(String path, SandboxWatchCallback onChange) async {
    await stop();
    try {
      _last = await readSignature();
    } catch (_) {
      _last = null;
    }
    _timer = Timer.periodic(pollInterval, (_) async {
      try {
        final String current = await readSignature();
        if (current != _last) {
          _last = current;
          onChange();
        }
      } catch (_) {
        // ignore — fichier momentanément indisponible
      }
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _last = null;
  }
}
