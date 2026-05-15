// Scalario — Anti-direct-platform-check (STORY-012).
//
// Aucun composant DS (`lib/components/`) ni feature (`lib/features/`) ne doit
// contenir d'appel direct à :
//   - kIsWeb
//   - Platform.isAndroid / Platform.isIOS / Platform.is<X>
//
// Tout passe par `lib/core/platform/` (PlatformInfo / PlatformCapabilities)
// pour rester testable et garder un point unique d'évolution.
//
// Exemptions :
//   - lib/core/platform/        (la couche d'adaptation elle-même)
//   - lib/main.dart             (bootstrap, OK ponctuellement)
//
// Lancement direct :
//   dart run scripts/check_no_direct_platform_check.dart
//
// Code de sortie : 0 = OK, 1 = violations détectées.

import 'dart:io';

const List<String> _scannedDirs = <String>[
  'lib/components',
  'lib/features',
];

const List<String> _exemptedPaths = <String>[
  'lib/core/platform/',
];

final List<({RegExp pattern, String label})> _forbiddenPatterns =
    <({RegExp pattern, String label})>[
  (
    pattern: RegExp(r'\bkIsWeb\b'),
    label: 'kIsWeb direct — utilisez PlatformInfo.isWeb',
  ),
  (
    pattern: RegExp(r'\bPlatform\.is[A-Z][a-zA-Z]+\b'),
    label: 'Platform.is<X> direct — utilisez PlatformInfo.is<X>',
  ),
];

bool _isExempted(String path) =>
    _exemptedPaths.any(path.replaceAll(r'\', '/').contains);

typedef Violation = ({String file, int line, String snippet, String label});

List<Violation> _scanFile(File f) {
  final hits = <Violation>[];
  if (_isExempted(f.path)) return hits;

  final lines = f.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    // Tolère les commentaires de ligne — la lint cible le code exécuté.
    final stripped = line.replaceAll(RegExp(r'//.*$'), '');
    for (final p in _forbiddenPatterns) {
      if (p.pattern.hasMatch(stripped)) {
        hits.add(
          (file: f.path, line: i + 1, snippet: line.trim(), label: p.label),
        );
      }
    }
  }
  return hits;
}

({int filesScanned, List<Violation> violations}) runPlatformCheckChecks({
  String workingDirectory = '.',
}) {
  final violations = <Violation>[];
  var filesScanned = 0;
  for (final dir in _scannedDirs) {
    final root = Directory('$workingDirectory/$dir');
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        filesScanned++;
        violations.addAll(_scanFile(entity));
      }
    }
  }
  return (filesScanned: filesScanned, violations: violations);
}

void main(List<String> args) {
  final result = runPlatformCheckChecks();
  final files = result.filesScanned;
  final violations = result.violations;

  if (violations.isEmpty) {
    stdout.writeln(
      '✓ check_no_direct_platform_check — $files fichiers scannés, 0 violation.',
    );
    return;
  }

  stderr.writeln(
    '✗ check_no_direct_platform_check — ${violations.length} violation(s) :',
  );
  for (final v in violations) {
    stderr.writeln('  ${v.file}:${v.line}  → ${v.label}');
    stderr.writeln('    ${v.snippet}');
  }
  exitCode = 1;
}
