import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Chemins SVG des logos Scalario.
/// Utiliser [AppLogos.wordmark] ou [AppLogos.monogram] pour obtenir
/// le bon widget selon le thème courant.
class AppLogos {
  AppLogos._();

  // --- Chemins statiques ---
  static const String wordmarkDark =
      'assets/images/scalario-wordmark-dark.svg';
  static const String wordmarkLight =
      'assets/images/scalario-wordmark-light.svg';
  static const String monogramDark =
      'assets/images/scalario-monogram-dark.svg';
  static const String monogramLight =
      'assets/images/scalario-monogram-light.svg';

  // --- Helpers ---

  /// Retourne le chemin du wordmark adapté à la luminosité du thème.
  static String wordmarkPath(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? wordmarkDark
        : wordmarkLight;
  }

  /// Retourne le chemin du monogramme adapté à la luminosité du thème.
  static String monogramPath(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? monogramDark
        : monogramLight;
  }

  /// Widget wordmark adapté au thème, largeur max 140 dp.
  static Widget wordmark(BuildContext context, {double maxWidth = 140}) {
    return SvgPicture.asset(
      wordmarkPath(context),
      width: maxWidth,
      fit: BoxFit.contain,
    );
  }

  /// Widget monogramme adapté au thème, taille fixe (défaut 24 dp).
  static Widget monogram(BuildContext context, {double size = 24}) {
    return SvgPicture.asset(
      monogramPath(context),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
