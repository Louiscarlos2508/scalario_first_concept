import 'package:flutter/material.dart';

import '../../design_system/tokens/colors.dart';
import '../../design_system/tokens/spacing.dart';
import '../../design_system/tokens/typography.dart';

/// Theme `InputDecoration` (TextField, DropdownMenu, SearchField).
///
/// Bordures `OutlineInputBorder` radius `sm`, focus `borderFocus`,
/// error `danger500`, hint `textDisabled`, fond `bgCard`.
/// Spec STORY-002 AC-10.
InputDecorationTheme buildInputDecorationTheme(ColorScheme colors) {
  final OutlineInputBorder base = OutlineInputBorder(
    borderRadius: BorderRadius.circular(ScalarioRadius.sm),
    borderSide: BorderSide(color: colors.outline),
  );

  return InputDecorationTheme(
    filled: true,
    fillColor: ScalarioColors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: ScalarioSpacing.space3,
      vertical: ScalarioSpacing.space3,
    ),
    border: base,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      borderSide: const BorderSide(color: ScalarioColors.neutral300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      borderSide: const BorderSide(
        color: ScalarioColors.interactivePrimary,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      borderSide: const BorderSide(color: ScalarioColors.danger500),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      borderSide: const BorderSide(
        color: ScalarioColors.danger500,
        width: 2,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ScalarioRadius.sm),
      borderSide: BorderSide(color: colors.outlineVariant),
    ),
    labelStyle: ScalarioTypography.fontInputLabel,
    floatingLabelStyle: ScalarioTypography.fontInputLabel,
    hintStyle: ScalarioTypography.fontInputHint.copyWith(
      color: ScalarioColors.textDisabled,
    ),
    helperStyle: ScalarioTypography.caption,
    errorStyle: ScalarioTypography.caption.copyWith(
      color: ScalarioColors.danger500,
    ),
  );
}
