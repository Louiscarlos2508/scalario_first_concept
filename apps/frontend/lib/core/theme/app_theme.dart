import 'package:flutter/material.dart';

/// Scalario design system color tokens (60-30-10 palette).
/// Source: docs/design-system.md — Color System section.
class AppColors {
  AppColors._();

  // 10% Accent — actions, CTAs, links, active states
  static const Color primary = Color(0xFF1565C0); // Bleu confiance

  // Semantic states
  static const Color success = Color(0xFF2E7D32); // Vert — confirmations
  static const Color error = Color(0xFFC62828); // Rouge — erreurs, alertes
  static const Color warning = Color(0xFFF9A825); // Jaune — en attente

  // 60% Dominant — neutral backgrounds
  static const Color background = Color(0xFFF5F5F5); // Fond app
  static const Color surface = Color(0xFFFFFFFF); // Cartes, modales

  // 30% Secondary — structure, text, borders
  static const Color textPrimary = Color(0xFF212121); // Texte principal
  static const Color textSecondary = Color(0xFF757575); // Texte secondaire
  static const Color border = Color(0xFFE0E0E0); // Bordures subtiles
}

/// Scalario typography tokens.
/// Source: docs/design-system.md — Typography section.
class AppTextStyles {
  AppTextStyles._();

  // Titre principal — 22sp Bold
  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Titre section — 18sp SemiBold
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Titre carte — 16sp SemiBold
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Corps — 14sp Regular
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Corps petit — 12sp Regular
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Étiquette — 11sp Medium (MAJUSCULES)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // Prix — 20sp Bold Monospace
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'monospace',
    height: 1.2,
  );

  // Quantité — 18sp Bold Monospace
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'monospace',
    height: 1.2,
  );
}

/// Scalario Material 3 theme.
/// Wire via: `MaterialApp(theme: AppTheme.light())`
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          error: AppColors.error,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          outline: AppColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // Typography
      textTheme: const TextTheme(
        displayMedium: AppTextStyles.displayMedium,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelSmall: AppTextStyles.labelSmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
      ),

      // ElevatedButton — Fitts: min 48dp height
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
      ),

      // FilledButton — primary CTA, Fitts: min 56dp height
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(88, 56)),
      ),

      // InputDecoration — OutlineInputBorder with design system border color
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Card — flat, 12dp radius, border
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
      ),
    );
  }
}
