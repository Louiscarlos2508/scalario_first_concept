import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/platform/platform_info.dart';

void main() {
  group('PlatformInfo — native host', () {
    test('exactement une plateforme native est vraie hors web', () {
      if (kIsWeb) return; // skip — testé séparément en build web.

      final hits = <bool>[
        PlatformInfo.isAndroid,
        PlatformInfo.isIOS,
        PlatformInfo.isLinux,
        PlatformInfo.isMacOS,
        PlatformInfo.isWindows,
      ].where((b) => b).length;

      expect(hits, 1, reason: 'exactly one native platform must be true');
      expect(PlatformInfo.isWeb, isFalse);
    });

    test('name correspond à la plateforme host', () {
      if (kIsWeb) {
        expect(PlatformInfo.name, 'web');
        return;
      }
      if (Platform.isLinux) expect(PlatformInfo.name, 'linux');
      if (Platform.isMacOS) expect(PlatformInfo.name, 'macos');
      if (Platform.isWindows) expect(PlatformInfo.name, 'windows');
      if (Platform.isAndroid) expect(PlatformInfo.name, 'android');
      if (Platform.isIOS) expect(PlatformInfo.name, 'ios');
    });

    test('isMobile = isAndroid || isIOS', () {
      expect(
        PlatformInfo.isMobile,
        PlatformInfo.isAndroid || PlatformInfo.isIOS,
      );
    });

    test('isDesktop = isLinux || isMacOS || isWindows', () {
      expect(
        PlatformInfo.isDesktop,
        PlatformInfo.isLinux || PlatformInfo.isMacOS || PlatformInfo.isWindows,
      );
    });
  });

  group('PlatformInfo — breakpoints web', () {
    testWidgets(
      'isMobileWeb / isDesktopWeb retournent false hors web',
      (tester) async {
        if (kIsWeb) return;

        late BuildContext capturedCtx;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 740)),
            child: Builder(
              builder: (ctx) {
                capturedCtx = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        expect(PlatformInfo.isMobileWeb(capturedCtx), isFalse);
        expect(PlatformInfo.isDesktopWeb(capturedCtx), isFalse);
      },
    );
  });
}
