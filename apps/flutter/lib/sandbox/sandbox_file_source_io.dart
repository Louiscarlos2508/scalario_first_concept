// Implémentation dart:io — desktop/mobile non-web.

import 'dart:io';

Future<String> readFileAsString(String path) => File(path).readAsString();

Stream<FileSystemEvent> watchFile(String path) =>
    File(path).watch(events: FileSystemEvent.modify | FileSystemEvent.create);
