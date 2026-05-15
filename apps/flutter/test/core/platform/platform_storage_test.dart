import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/platform/platform_specific/storage.dart';

void main() {
  test('createPlatformStorage retourne le backend de la plateforme host', () {
    final storage = createPlatformStorage();
    expect(storage.backend, kIsWeb ? 'web' : 'io');
    expect(storage.location, isNotEmpty);
  });
}
