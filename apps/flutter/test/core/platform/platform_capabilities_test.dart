import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/platform/platform_capabilities.dart';
import 'package:scalario/core/platform/platform_info.dart';

void main() {
  group('PlatformCapabilities', () {
    test('filePicker dispo partout', () {
      expect(PlatformCapabilities.filePickerAvailable, isTrue);
    });

    test('bluetooth aligné sur isMobile', () {
      expect(
        PlatformCapabilities.bluetoothAvailable,
        PlatformInfo.isMobile,
      );
    });

    test('camera aligné sur isMobile (Phase 1, pas de getUserMedia web)', () {
      expect(
        PlatformCapabilities.cameraAvailable,
        PlatformInfo.isMobile,
      );
    });

    test('push notifications mobile-only Phase 1', () {
      expect(
        PlatformCapabilities.pushNotificationsAvailable,
        PlatformInfo.isMobile,
      );
    });

    test('nativeFileSystem = !isWeb', () {
      expect(
        PlatformCapabilities.nativeFileSystemAvailable,
        !PlatformInfo.isWeb,
      );
    });

    test('snapshot expose toutes les clés et reste booléen', () {
      final snap = PlatformCapabilities.snapshot();
      expect(snap.keys, containsAll(<String>[
        'bluetoothAvailable',
        'cameraAvailable',
        'filePickerAvailable',
        'pushNotificationsAvailable',
        'nativeFileSystemAvailable',
      ]));
      for (final v in snap.values) {
        expect(v, isA<bool>());
      }
    });
  });
}
