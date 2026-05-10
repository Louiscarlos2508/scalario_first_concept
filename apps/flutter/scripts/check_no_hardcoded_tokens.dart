// Scalario — Anti-hardcode token check.
//
// Vérifie que `lib/components/` et `lib/features/` n'utilisent jamais :
//   - Color(0x…)              → toujours via ScalarioColors.*
//   - Colors.<named>          → toujours via ScalarioColors.*
//   - EdgeInsets.{all,symmetric,fromLTRB}(<num literal>)  → ScalarioSpacing.*
//   - BorderRadius.circular(<num literal>)                → ScalarioRadius.*
//
// Le dossier `lib/core/design_system/tokens/` est exempté — il définit les
// tokens. Le dossier `lib/main.dart` (root) est aussi scanné.
//
// Lancement direct :
//   dart run scripts/check_no_hardcoded_tokens.dart
//
// Le test `test/core/design_system/tokens/no_hardcoded_tokens_test.dart`
// invoque ce vérificateur via `runHardcodeChecks()`.
//
// Code de sortie : 0 = OK, 1 = violations détectées.

import 'dart:io';

const List<String> _scannedDirs = <String>[
  'lib/components',
  'lib/features',
];

/// Fichiers / glob-paths qui peuvent contenir des tokens hardcodés (ex: les
/// fichiers tokens eux-mêmes). Toujours résolus en chemin POSIX (slash).
const List<String> _exemptedPaths = <String>[
  'lib/core/design_system/tokens/',
];

/// Patterns interdits hors de `lib/core/design_system/tokens/`.
final List<({RegExp pattern, String label})> _forbiddenPatterns =
    <({RegExp pattern, String label})>[
  (
    pattern: RegExp(r'Color\s*\(\s*0x[0-9A-Fa-f]+'),
    label: 'Color(0x…) literal — utilisez ScalarioColors.*',
  ),
  (
    // Colors.red, Colors.blue, ... (Material Colors palette directe)
    pattern: RegExp(r'\bColors\.[a-zA-Z]'),
    label: 'Colors.* (Material) — utilisez ScalarioColors.*',
  ),
  (
    // Le négatif lookbehind `(?<!\w)` ignore les digits qui font partie d'un
    // identifier (ex: `ScalarioSpacing.space4`) — seuls les littéraux nus
    // (`16`, `-8`) sont signalés.
    pattern: RegExp(
        r'EdgeInsets\.(?:all|symmetric|fromLTRB|only)\s*\([^)]*?(?<!\w)-?\d'),
    label:
        'EdgeInsets avec littéral numérique — utilisez ScalarioSpacing.space*',
  ),
  (
    pattern: RegExp(r'BorderRadius\.circular\s*\(\s*\d'),
    label: 'BorderRadius.circular(<n>) — utilisez ScalarioRadius.*',
  ),
];

/// Une violation détectée.
class HardcodeViolation {
  HardcodeViolation({
    required this.file,
    required this.line,
    required this.lineNumber,
    required this.label,
  });

  final String file;
  final String line;
  final int lineNumber;
  final String label;

  @override
  String toString() => '$file:$lineNumber — $label\n  > ${line.trim()}';
}

/// Scan tous les fichiers `.dart` sous [_scannedDirs] et retourne la liste des
/// violations. Les dossiers absents sont ignorés (early stories n'ont pas
/// encore créé `lib/components/` ou `lib/features/`).
List<HardcodeViolation> runHardcodeChecks({String root = '.'}) {
  final List<HardcodeViolation> violations = <HardcodeViolation>[];

  for (final String dir in _scannedDirs) {
    final Directory target = Directory('$root/$dir');
    if (!target.existsSync()) {
      continue;
    }

    for (final FileSystemEntity entity
        in target.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (_isExempted(entity.path)) continue;

      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String raw = lines[i];
        final String stripped = _stripComment(raw);
        if (stripped.trim().isEmpty) continue;

        for (final ({RegExp pattern, String label}) rule
            in _forbiddenPatterns) {
          if (rule.pattern.hasMatch(stripped)) {
            violations.add(HardcodeViolation(
              file: entity.path,
              line: raw,
              lineNumber: i + 1,
              label: rule.label,
            ));
          }
        }
      }
    }
  }

  return violations;
}

bool _isExempted(String path) {
  final String posix = path.replaceAll(r'\', '/');
  for (final String exempt in _exemptedPaths) {
    if (posix.contains(exempt)) return true;
  }
  return false;
}

String _stripComment(String line) {
  final int idx = line.indexOf('//');
  if (idx == -1) return line;
  return line.substring(0, idx);
}

void main(List<String> args) {
  final List<HardcodeViolation> violations = runHardcodeChecks();
  if (violations.isEmpty) {
    stdout.writeln(
        '✓ Aucune valeur hardcodée détectée dans lib/components/ et lib/features/.');
    exit(0);
  }

  stderr.writeln(
      '✗ ${violations.length} violation(s) de tokens détectée(s) :\n');
  for (final HardcodeViolation v in violations) {
    stderr
      ..writeln(v)
      ..writeln();
  }
  exit(1);
}
