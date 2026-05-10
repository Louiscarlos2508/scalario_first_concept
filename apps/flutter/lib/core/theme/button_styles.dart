import 'package:flutter/material.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/spacing.dart';
import '../design_system/tokens/typography.dart';

/// Variantes Scalario nommées pour `FilledButton` / `OutlinedButton` /
/// `TextButton` Material 3.
///
/// Pas de nouveau widget — on expose des `ButtonStyle` réutilisables que le
/// dev passe via `style:` aux primitives Material 3 :
///
/// ```dart
/// FilledButton(
///   style: ScalarioButtonStyles.primary,
///   onPressed: ...,
///   child: Text('Vendre'),
/// );
///
/// FilledButton(
///   style: ScalarioButtonStyles.danger,
///   onPressed: ...,
///   child: Text('Supprimer'),
/// );
/// ```
///
/// Convention de nommage : `danger` est le terme utilisé dans le code Dart
/// (court, idiomatique) ; `destructive` est l'alias exporté pour cohérence
/// avec la spec ASCII (`design-process/D-Design-System/components/05-actions.md`).
///
/// Spec STORY-002 AC-15, AC-16.
abstract final class ScalarioButtonStyles {
  /// Action primaire (`FilledButton` par défaut). Bleu primary-500.
  static final ButtonStyle primary = FilledButton.styleFrom(
    backgroundColor: ScalarioColors.primary500,
    foregroundColor: ScalarioColors.white,
    minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightPrimary),
    padding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space4,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    textStyle: ScalarioTypography.fontButton,
  );

  /// Action secondaire (`OutlinedButton`). Bordure primary-500, texte
  /// primary-500, fond transparent.
  static final ButtonStyle secondary = OutlinedButton.styleFrom(
    foregroundColor: ScalarioColors.primary500,
    minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightPrimary),
    padding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space4,
    ),
    side: const BorderSide(
      color: ScalarioColors.primary500,
      width: 1.5,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    textStyle: ScalarioTypography.fontButton,
  );

  /// Ghost (`TextButton`). Pas de fond ni bordure — texte primary-500.
  /// Hauteur 40 (plus dense, usage en toolbar / inline).
  static final ButtonStyle ghost = TextButton.styleFrom(
    foregroundColor: ScalarioColors.primary500,
    minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightSecondary),
    padding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space3,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    textStyle: ScalarioTypography.fontButton,
  );

  /// Destructive (`FilledButton` rouge). Fond danger-500.
  static final ButtonStyle danger = FilledButton.styleFrom(
    backgroundColor: ScalarioColors.danger500,
    foregroundColor: ScalarioColors.white,
    minimumSize: const Size.fromHeight(ScalarioLayout.buttonHeightPrimary),
    padding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space4,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
    ),
    textStyle: ScalarioTypography.fontButton,
  );

  /// Alias DS — la spec ASCII parle de `destructive`, on garde les deux noms.
  static ButtonStyle get destructive => danger;
}
