/// STORY-012 — stub par défaut (jamais sélectionné car `dart:io` OU
/// `dart:html` est toujours présent). Existe pour satisfaire le pattern
/// `conditional imports` et documenter le contrat.
library;

import 'platform_storage.dart';

PlatformStorage createPlatformStorage() =>
    throw UnsupportedError(
      'No PlatformStorage implementation available on this platform.',
    );
