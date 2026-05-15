import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'bdui_engine_config.dart';

/// Wrapper autour de `Timeline.timeSync` qui peut être désactivé via
/// [BDUIEngineConfig.enableTimeline] (zero overhead en release mode).
///
/// STORY-008 — AC-09. Visible dans Flutter DevTools → Performance.
final class PerfMetrics {
  const PerfMetrics({this.config = BDUIEngineConfig.defaults});

  final BDUIEngineConfig config;

  /// Exécute [body] sous une `Timeline.timeSync` nommée `BDUI.$name`.
  T timeSync<T>(String name, T Function() body) {
    if (kReleaseMode || !config.enableTimeline) {
      return body();
    }
    return developer.Timeline.timeSync('BDUI.$name', body);
  }

  Future<T> timeSyncAsync<T>(String name, Future<T> Function() body) async {
    if (kReleaseMode || !config.enableTimeline) {
      return body();
    }
    developer.Timeline.startSync('BDUI.$name');
    try {
      return await body();
    } finally {
      developer.Timeline.finishSync();
    }
  }
}
