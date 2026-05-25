import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../../engine/canvas_layout/breakpoints.dart';

/// STORY-012 — informations plateforme exposées en un seul point.
///
/// Tous les composants du DS et widgets BDUI doivent passer par cette classe.
/// Aucun `kIsWeb` ni `Platform.is*` direct dans `lib/components/` ou
/// `lib/features/` — vérifié par `scripts/check_no_direct_platform_check.dart`
/// en CI.
///
/// Les breakpoints `isMobileWeb` / `isDesktopWeb` réutilisent le canon
/// projet ([BreakpointResolver]) — pas de breakpoint dupliqué.
abstract final class PlatformInfo {
  static bool get isWeb => kIsWeb;

  /// Vraie sur Android natif. Faux en web mobile Android (utiliser
  /// [isMobileWeb] pour ça).
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// Mobile natif (Android ou iOS, hors web).
  static bool get isMobile => isAndroid || isIOS;

  /// Desktop natif (hors web).
  static bool get isDesktop => isLinux || isMacOS || isWindows;

  /// Web + viewport `< 600` (canon [Breakpoint.mobile]).
  static bool isMobileWeb(BuildContext ctx) {
    if (!kIsWeb) return false;
    return BreakpointResolver.fromWidth(MediaQuery.of(ctx).size.width) ==
        Breakpoint.mobile;
  }

  /// Web + viewport `> 1024` (canon [Breakpoint.desktop]).
  static bool isDesktopWeb(BuildContext ctx) {
    if (!kIsWeb) return false;
    return BreakpointResolver.fromWidth(MediaQuery.of(ctx).size.width) ==
        Breakpoint.desktop;
  }

  /// Nom court humain — pour logs / showcase / debug.
  static String get name {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'unknown';
  }
}
