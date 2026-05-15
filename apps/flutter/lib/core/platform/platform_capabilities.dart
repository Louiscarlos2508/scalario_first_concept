import 'platform_info.dart';

/// STORY-012 — feature flags par plateforme.
///
/// Phase 1 livre des **flags**, pas les implémentations runtime (Bluetooth
/// balance / imprimante = STORY-PD-XX Phase 2). Les composants BDUI lisent
/// ces flags pour afficher / masquer des options ; le runtime branche les
/// vrais drivers via [platform_specific] et conditional imports.
abstract final class PlatformCapabilities {
  /// Bluetooth (balance + imprimante thermique POS). Mobile uniquement Phase 1.
  static bool get bluetoothAvailable => PlatformInfo.isMobile;

  /// Caméra (scan code-barres). Mobile natif Phase 1. Web nécessite HTTPS +
  /// getUserMedia ; flag mis à `false` Phase 1 tant qu'on n'a pas validé le
  /// fallback web.
  static bool get cameraAvailable => PlatformInfo.isMobile;

  /// File picker disponible partout (HTML input file + native pickers).
  static bool get filePickerAvailable => true;

  /// Push notifications mobiles. Web Push Phase 2 (STORY backlog).
  static bool get pushNotificationsAvailable => PlatformInfo.isMobile;

  /// Persistance native (`dart:io` + sqlite/Drift native).
  /// Faux sur web — l'implémentation web passe par IndexedDB (STORY-035).
  static bool get nativeFileSystemAvailable => !PlatformInfo.isWeb;

  /// Carte JSON sérialisable des flags — utile pour debug, showcase,
  /// remote-config diagnostics.
  static Map<String, bool> snapshot() => <String, bool>{
        'bluetoothAvailable': bluetoothAvailable,
        'cameraAvailable': cameraAvailable,
        'filePickerAvailable': filePickerAvailable,
        'pushNotificationsAvailable': pushNotificationsAvailable,
        'nativeFileSystemAvailable': nativeFileSystemAvailable,
      };
}
