// Stub Web — `dart:io` indisponible. La sandbox tombe en mode bundle/polling.

Future<String> readFileAsString(String path) {
  throw UnsupportedError(
    'FileJsonSource indisponible sur cette plateforme (Web). '
    'Utiliser BundleJsonSource + polling.',
  );
}

Stream<dynamic> watchFile(String path) {
  throw UnsupportedError(
    'File watcher dart:io indisponible sur Web. '
    'Utiliser SandboxFileWatcher.polling à la place.',
  );
}
