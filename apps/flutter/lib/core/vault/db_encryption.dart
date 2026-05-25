import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
// sqlcipher_flutter_libs s'enregistre comme lib sqlite3 au moment de l'import.
// ignore: unused_import
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/common.dart';

import 'auth_storage.dart';

/// Gestion du chiffrement SQLCipher pour [ScalarioDatabase].
///
/// AC-11 : le fichier SQLite est chiffré via SQLCipher AES-256.
/// La passphrase 32 bytes base64 est stockée dans [AuthStorage].
///
/// AC-13 : si la passphrase est perdue, la DB est supprimée et
/// un bootstrap forcé a lieu au prochain login.
///
/// Utilise `drift_flutter` avec `DriftNativeOptions.setup` pour
/// appliquer `PRAGMA key` avant toute opération Drift.
final class DbEncryption {
  DbEncryption(this._authStorage);

  final AuthStorage _authStorage;

  /// Ouvre une connexion Drift chiffrée avec SQLCipher (AC-11).
  ///
  /// Premier lancement : génère une passphrase 32 bytes aléatoire.
  /// Lancements suivants : lit la passphrase depuis secure storage.
  Future<QueryExecutor> openEncrypted() async {
    String? passphrase = await _authStorage.readDbPassphrase();

    if (passphrase == null) {
      passphrase = _generatePassphrase();
      _authStorage.saveDbPassphrase(passphrase);
    }

    // sqlcipher_flutter_libs remplace la lib sqlite3 système
    // à l'import (side-effect FFI bindings).
    // Le callback `setup` applique la passphrase.
    return driftDatabase(
      name: 'scalario',
      native: DriftNativeOptions(
        setup: (CommonDatabase db) {
          db.execute("PRAGMA key = '$passphrase';");
          db.execute('PRAGMA journal_mode=WAL;');
        },
      ),
    );
  }

  /// AC-13 — efface les secrets du secure storage.
  Future<void> handlePassphraseLost() async {
    await _authStorage.clearAll();
  }

  String _generatePassphrase() {
    final Random rng = Random.secure();
    final List<int> bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }
}
