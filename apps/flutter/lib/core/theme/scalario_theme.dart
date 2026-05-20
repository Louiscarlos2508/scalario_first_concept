import 'package:flutter/material.dart';

import '../design_system/tokens/colors.dart';
import 'color_scheme_builder.dart';
import 'component_themes/button_themes.dart';
import 'component_themes/data_themes.dart';
import 'component_themes/feedback_themes.dart';
import 'component_themes/input_themes.dart';
import 'component_themes/surface_themes.dart';
import 'text_theme_builder.dart';
import 'theme_extensions.dart';

/// Point d'entrée du thème Scalario.
///
/// `ScalarioTheme.light()` et `ScalarioTheme.dark()` retournent des
/// `ThemeData` Material 3 entièrement construits depuis les tokens
/// Scalario (`lib/core/design_system/tokens/`).
///
/// **Base : Material 3 natif Flutter (2026-05-10).**
/// Material 3 est déjà flat, accessible, à jour, et évite toute dépendance
/// UI externe. Le DS Scalario s'applique via `ThemeData` + `ThemeExtensions`.
///
/// **Surface tinting :** M3 applique par défaut une teinte primary
/// translucide sur les surfaces élévées (`surfaceTintColor`). Scalario
/// utilise une palette neutre — `surfaceTintColor: Colors.transparent` est
/// donc imposé sur tous les composants concernés (Card, AppBar, Dialog,
/// BottomSheet, FAB).
///
/// Usage :
/// ```dart
/// MaterialApp(
///   theme: ScalarioTheme.light(),
///   darkTheme: ScalarioTheme.dark(),
///   themeMode: ThemeMode.system,
///   home: ...,
/// );
/// ```
abstract final class ScalarioTheme {
  static ThemeData light() => _build(brightness: Brightness.light);

  static ThemeData dark() => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final ColorScheme colors = brightness == Brightness.dark
        ? ScalarioColorSchemeBuilder.dark()
        : ScalarioColorSchemeBuilder.light();
    final TextTheme textTheme = ScalarioTextThemeBuilder.build(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      textTheme: textTheme,
      // Scaffold = un cran plus sombre que `surface` pour que les Cards
      // (qui héritent de `surface`) se détachent visiblement du fond.
      // Light : neutral100 (#F0F0F8) vs Card white.
      // Dark  : neutral900 (#1A1A2E) vs Card bgCardDark (#22223A).
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? ScalarioColors.neutral900
          : ScalarioColors.neutral100,
      // Component themes — listés explicitement pour qu'aucun composant M3
      // ne retombe sur ses defaults non-brandés.
      filledButtonTheme: buildFilledButtonTheme(colors),
      outlinedButtonTheme: buildOutlinedButtonTheme(colors),
      textButtonTheme: buildTextButtonTheme(colors),
      elevatedButtonTheme: buildElevatedButtonTheme(colors),
      cardTheme: buildCardTheme(colors),
      inputDecorationTheme: buildInputDecorationTheme(colors),
      dialogTheme: buildDialogTheme(colors),
      appBarTheme: buildAppBarTheme(colors),
      bottomSheetTheme: buildBottomSheetTheme(colors),
      floatingActionButtonTheme: buildFabTheme(colors),
      badgeTheme: buildBadgeTheme(colors),
      dividerTheme: buildDividerTheme(colors),
      iconTheme: buildIconTheme(colors),
      snackBarTheme: buildSnackBarTheme(colors),
      tooltipTheme: buildTooltipTheme(colors),
      dataTableTheme: buildDataTableTheme(colors),
      bottomNavigationBarTheme: buildBottomNavTheme(colors),
      navigationBarTheme: buildNavigationBarTheme(colors),
      chipTheme: buildChipTheme(colors),
      listTileTheme: buildListTileTheme(colors),
      // Sémantiques métier non couvertes par ColorScheme.
      extensions: <ThemeExtension<dynamic>>[
        ScalarioColorsExtension.fromBrightness(brightness),
        ScalarioSpacingExtension.standard,
        ScalarioElevationExtension.fromBrightness(brightness),
      ],
    );
  }
}
