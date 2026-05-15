// STORY-009 — Sandbox dev-only.
//
// Console légère qui capture les logs structurés émis pendant la session de
// sandbox. Aide au debug quand un composant échoue silencieusement.

import 'package:flutter/material.dart';

/// Niveau de log capturé par la [SandboxConsole].
enum SandboxLogLevel { info, warning, error }

@immutable
class SandboxLogEntry {
  const SandboxLogEntry({
    required this.timestamp,
    required this.level,
    required this.source,
    required this.message,
    this.error,
  });

  final DateTime timestamp;
  final SandboxLogLevel level;
  final String source;
  final String message;
  final Object? error;
}

/// Buffer circulaire 50 entrées max, observable via [ChangeNotifier].
class SandboxConsoleController extends ChangeNotifier {
  SandboxConsoleController({this.maxEntries = 50});

  final int maxEntries;
  final List<SandboxLogEntry> _entries = <SandboxLogEntry>[];

  List<SandboxLogEntry> get entries => List<SandboxLogEntry>.unmodifiable(_entries);

  void log(
    SandboxLogLevel level,
    String source,
    String message, {
    Object? error,
  }) {
    _entries.add(
      SandboxLogEntry(
        timestamp: DateTime.now(),
        level: level,
        source: source,
        message: message,
        error: error,
      ),
    );
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
    notifyListeners();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }
}

/// Affiche les entrées du [SandboxConsoleController] dans une zone scrollable.
class SandboxConsole extends StatelessWidget {
  const SandboxConsole({super.key, required this.controller});

  final SandboxConsoleController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final List<SandboxLogEntry> entries = controller.entries;
        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Console vide.', style: TextStyle(fontSize: 12)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: entries.length,
          itemBuilder: (BuildContext ctx, int i) {
            final SandboxLogEntry e = entries[entries.length - 1 - i];
            final Color color = switch (e.level) {
              SandboxLogLevel.error => Colors.red.shade700,
              SandboxLogLevel.warning => Colors.orange.shade700,
              SandboxLogLevel.info => Colors.blueGrey.shade700,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Text(
                '[${e.timestamp.toIso8601String().substring(11, 19)}] '
                '${e.level.name.toUpperCase()} ${e.source} — ${e.message}'
                '${e.error != null ? "\n    ${e.error}" : ""}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: color,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
