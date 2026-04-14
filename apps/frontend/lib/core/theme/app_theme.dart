import 'package:flutter/material.dart';

/// Scalario design system color tokens.
/// Source: Figma — Scalario maquette / node 4:2 — Design System (2026-04-06)
/// https://www.figma.com/design/ZzdrrA4XzmTjLEq4AL7Jha/Scalario-maquette?node-id=4-2
///
/// Palette Material grey alignée sur Figma. Ne pas réintroduire Slate sans
/// synchroniser Figma au préalable.
class AppColors {
  AppColors._();

  // Accent — actions, CTAs, links, active states
  static const Color primary = Color(0xFF1565C0); // Bleu confiance
  static const Color primaryDark = Color(0xFF0D47A1); // Bleu sombre — gradients

  // Trend text highlight (positive on dark bg)
  static const Color trendGreenLight = Color(0xFFA5D6A7); // vert clair sur fond bleu

  // Semantic states
  static const Color success = Color(0xFF2E7D32); // Vert — confirmations
  static const Color error = Color(0xFFC62828); // Rouge — erreurs, alertes
  static const Color warning = Color(0xFFF9A825); // Jaune — en attente

  // Neutrals — Material grey (Figma section 1)
  static const Color background = Color(0xFFF5F5F5); // fond app
  static const Color surface = Color(0xFFFFFFFF); // Cartes, modales
  static const Color textPrimary = Color(0xFF212121); // texte principal
  static const Color textSecondary = Color(0xFF757575); // texte secondaire
  static const Color border = Color(0xFFE0E0E0); // bordures cartes/inputs

  // AppBar dark — utilisé dans toutes les m-appbar et d-appbar
  static const Color appbar = Color(0xFF0F172A); // slate-900

  // Sheet / bottom-sheet inputs (Figma section 1b)
  static const Color sheetBg = Color(0xFFF8FAFC);
  static const Color sheetBorder = Color(0xFFE2E8F0);
  static const Color sheetFocus = Color(0xFF1A73E8);

  // Chips status (Figma section 7)
  static const Color chipSuccessBg = Color(0xFFE8F5E9);
  static const Color chipSuccessBorder = Color(0xFFC8E6C9);
  static const Color chipSuccessText = Color(0xFF2E7D32);

  static const Color chipWarningBg = Color(0xFFFFF8E1);
  static const Color chipWarningBorder = Color(0xFFFFE7A6);
  static const Color chipWarningText = Color(0xFFB27A00);

  static const Color chipErrorBg = Color(0xFFFFEBEE);
  static const Color chipErrorBorder = Color(0xFFFFCDD2);
  static const Color chipErrorText = Color(0xFFC62828);

  // Chip action (primary tint)
  static const Color chipActionBg = Color(0xFFE3F2FD);
  static const Color chipActionBorder = Color(0xFFBBDEFB);
  static const Color chipActionText = Color(0xFF1565C0);

  // Couleurs rôles — pour avatars, borders, pills d'identification persona
  static const Color rolePatron = Color(0xFF92400E); // amber-800
  static const Color roleGerant = Color(0xFF1E40AF); // blue-800
  static const Color roleVendeur = Color(0xFF166534); // green-800
  static const Color roleCommercial = Color(0xFF6B21A8); // purple-800

  // Couleurs marque (logo Scalario monogramme)
  static const Color brandYellow = Color(0xFFFFCC00);
  static const Color brandBlue = Color(0xFF1A73E8);
  static const Color brandGreen = Color(0xFF34A853);
  static const Color brandRed = Color(0xFFEA4335);

  // Canaux de paiement
  static const Color payCash = Color(0xFF34A853);
  static const Color payWave = Color(0xFF1DC8DB);
  static const Color payOrangeMoney = Color(0xFFFF6F00);
  static const Color payWhatsapp = Color(0xFF25D366);

  // Échelle fraîcheur produit (sc06 — fresh produce)
  static const Color freshGreen = Color(0xFF16A34A); // frais OK
  static const Color freshOrange = Color(0xFFF59E0B); // bientôt
  static const Color freshRed = Color(0xFFDC2626); // périmé / urgent
}

/// Espacement (multiples de 4) — utilisé dans paddings, gaps, margins.
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border radii — du plus petit (badges) au plus grand (cards).
class AppRadii {
  AppRadii._();
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 14;
  static const double xxl = 16;
  static const double sheet = 24;
  static const double frame = 32;
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

  // Étiquette — 11sp Medium (MAJUSCULES — uppercase appliqué par l'appelant)
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // Prix — 20sp Bold Roboto Mono
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'RobotoMono',
    height: 1.2,
  );

  // Quantité — 18sp Bold Roboto Mono
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: 'RobotoMono',
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

    final btnShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

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
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: btnShape,
        ),
      ),

      // FilledButton — primary CTA, Fitts: min 56dp height
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 56),
          shape: btnShape,
        ),
      ),

      // OutlinedButton — secondary CTA
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(64, 48),
          shape: btnShape,
        ),
      ),

      // TextButton — tertiary CTA
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 48),
          shape: btnShape,
        ),
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
