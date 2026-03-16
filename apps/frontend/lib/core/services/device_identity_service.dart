import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates and persists a stable, human-readable device identifier.
///
/// Format: `caisse-{platform}-{6-char-hex}`
/// Example: `caisse-android-a3f9c2`
///
/// The ID is generated once on first use and persisted in SharedPreferences.
/// Subsequent calls always return the same ID — never regenerated.
class DeviceIdentityService {
  static const String _prefsKey = 'scalario_device_id';

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _generate();
    await prefs.setString(_prefsKey, generated);
    return generated;
  }

  String _generate() {
    final platform = _platformTag();
    final hex = _randomHex(6);
    return 'caisse-$platform-$hex';
  }

  String _platformTag() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'device';
    }
  }

  String _randomHex(int length) {
    const chars = '0123456789abcdef';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
