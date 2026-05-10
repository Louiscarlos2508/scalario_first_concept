// Vérifie qu'aucun fichier sous `lib/components/` ou `lib/features/` ne
// contient de couleur, padding ou border-radius hardcodés. Chaque violation
// doit passer par `ScalarioColors.*`, `ScalarioSpacing.space*`, ou
// `ScalarioRadius.*`.
//
// Le scanner est défini dans `scripts/check_no_hardcoded_tokens.dart`.
// Sprint 1 : ces dossiers n'existent pas encore — le test passe en no-op.
// Dès STORY-003+, le test commence à scanner et bloquera tout PR qui hardcode.

import 'package:flutter_test/flutter_test.dart';

import '../../../../scripts/check_no_hardcoded_tokens.dart';

void main() {
  test('Aucune valeur hardcodée dans lib/components/ et lib/features/', () {
    final List<HardcodeViolation> violations = runHardcodeChecks();
    expect(
      violations,
      isEmpty,
      reason: '${violations.length} violation(s) — utiliser les tokens '
          'ScalarioColors / ScalarioSpacing / ScalarioRadius :\n${violations.join('\n')}',
    );
  });
}
