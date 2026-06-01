// STORY-009 — Sandbox dev-only.
//
// Charge un fichier JSON sandbox (`assets/sandbox/*.json`) en deux modes :
//
//  1. `BundleSource` (défaut)  → `rootBundle.loadString` — tous les devices.
//  2. `FileSource` (desktop)   → `File(path).readAsString` — permet le hot
//                                reload < 300ms depuis les sources du repo.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'sandbox_file_source_stub.dart'
    if (dart.library.io) 'sandbox_file_source_io.dart' as fs;

/// Liste fixe des fixtures sandbox (AC-15). Stable, vérifiée à la
/// construction. Permet de remplir un Dropdown sans `AssetManifest`.
const List<String> kSandboxFixtureIds = <String>[
  'retail_dashboard',
  'simple_form',
  'transactions_list',
  'empty_screen',
  'error_state',
  // Blandine tenant screens (BDUI zones format)
  'dashboard_owner',
  'pos_commercial',
  'stock_list',
  'loss_form',
  'delivery_validation',
  'daily_report',
  'inventory_count',
  'alert_detail',
];

/// Erreur de parsing JSON enrichie avec ligne/colonne pour [SandboxErrorView].
class SandboxParseException implements Exception {
  const SandboxParseException({
    required this.path,
    required this.message,
    this.line,
    this.column,
    this.source,
  });

  final String path;
  final String message;
  final int? line;
  final int? column;

  /// Texte brut tel que lu — utile pour afficher le voisinage de l'erreur.
  final String? source;

  @override
  String toString() {
    final String pos = (line != null) ? ' (ligne $line, col $column)' : '';
    return 'SandboxParseException at $path$pos: $message';
  }
}

/// Source de chargement abstraite.
@immutable
abstract class SandboxJsonSource {
  const SandboxJsonSource();
  String describePath(String fixtureId);
  Future<String> read(String fixtureId);
}

/// Source `rootBundle` — fonctionne partout (web, mobile, desktop) mais ne
/// suit pas les modifications de fichier hors hot restart.
class BundleJsonSource extends SandboxJsonSource {
  const BundleJsonSource({AssetBundle? bundle, this.prefix = 'assets/sandbox/'})
      : _bundle = bundle;

  final AssetBundle? _bundle;
  final String prefix;

  AssetBundle get _resolved => _bundle ?? rootBundle;

  @override
  String describePath(String fixtureId) => '$prefix$fixtureId.json';

  @override
  Future<String> read(String fixtureId) =>
      _resolved.loadString(describePath(fixtureId), cache: false);
}

/// Source filesystem — utilisée sur desktop pour le hot reload.
///
/// Indirection via `sandbox_file_source_{io,stub}.dart` pour rester
/// compilable sur Flutter Web (où `dart:io` est absent).
class FileJsonSource extends SandboxJsonSource {
  const FileJsonSource({required this.projectRoot, this.prefix = 'assets/sandbox/'});

  /// Chemin absolu du sous-répertoire `apps/flutter/` (contient `assets/`).
  final String projectRoot;
  final String prefix;

  @override
  String describePath(String fixtureId) =>
      '$projectRoot/$prefix$fixtureId.json';

  @override
  Future<String> read(String fixtureId) =>
      fs.readFileAsString(describePath(fixtureId));
}

/// Charge + parse une fixture sandbox depuis la source fournie. Toute erreur
/// est traduite en [SandboxParseException] avec, si possible, le couple
/// ligne/colonne du parser (AC-11).
class SandboxJsonLoader {
  const SandboxJsonLoader({this.source = const BundleJsonSource()});

  final SandboxJsonSource source;

  String describePath(String fixtureId) => source.describePath(fixtureId);

  Future<Map<String, dynamic>> load(String fixtureId) async {
    final String path = source.describePath(fixtureId);
    String raw;
    try {
      raw = await source.read(fixtureId);
    } catch (e) {
      throw SandboxParseException(
        path: path,
        message: 'Lecture du fichier impossible: $e',
      );
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw SandboxParseException(
          path: path,
          message:
              'Le JSON racine doit être un objet (reçu ${decoded.runtimeType}).',
          source: raw,
        );
      }
      return decoded;
    } on FormatException catch (e) {
      final _Position pos = _resolvePosition(raw, e.offset);
      throw SandboxParseException(
        path: path,
        message: e.message,
        line: pos.line,
        column: pos.column,
        source: raw,
      );
    }
  }
}

class _Position {
  const _Position(this.line, this.column);
  final int? line;
  final int? column;
}

_Position _resolvePosition(String source, int? offset) {
  if (offset == null || offset < 0) return const _Position(null, null);
  int line = 1;
  int col = 1;
  final int safeOffset = offset > source.length ? source.length : offset;
  for (int i = 0; i < safeOffset; i++) {
    if (source.codeUnitAt(i) == 0x0A) {
      line++;
      col = 1;
    } else {
      col++;
    }
  }
  return _Position(line, col);
}
