import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// `InputDecoration` configurée pour la variante "sheet" du design system.
/// Source : Figma node 4:2 — section 6 (Inputs, palette sheet).
///
/// Utiliser dans les bottom sheets et formulaires sur fond clair :
/// ```dart
/// TextField(
///   decoration: scalarioSheetInputDecoration(labelText: 'Quantité'),
/// )
/// ```
InputDecoration scalarioSheetInputDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final radius = BorderRadius.circular(8);
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.sheetBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.sheetBorder),
      borderRadius: radius,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.sheetBorder),
      borderRadius: radius,
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.sheetFocus, width: 1.5),
      borderRadius: radius,
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.error),
      borderRadius: radius,
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      borderRadius: radius,
    ),
  );
}
