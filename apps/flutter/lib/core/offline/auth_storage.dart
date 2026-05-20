// ignore_for_file: avoid_print

import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';

/// Stockage sécurisé des secrets d'authentification via `flutter_secure_storage`.
///
/// AC-12 : JWT Access + Refresh **jamais** dans Drift, jamais en SharedPreferences.
/// AC-13 : la clé passphrase DB est stockée ici aussi (récupération propre).
///
/// Keys utilisées :
/// - `scalario.auth.access`  → JWT access token
/// - `scalario.auth.refresh` → JWT refresh token
/// - `scalario.db.passphrase` → passphrase SQLCipher 32 bytes base64
final class AuthStorage {
  AuthStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // --- JWT tokens (AC-12) ---

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  Future<String?> readAccessToken() =>
      _storage.read(key: _accessKey);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  Future<String?> readRefreshToken() =>
      _storage.read(key: _refreshKey);

  // --- Passphrase DB (AC-11, AC-13) ---

  Future<void> saveDbPassphrase(String passphrase) =>
      _storage.write(key: _dbPassphraseKey, value: passphrase);

  Future<String?> readDbPassphrase() =>
      _storage.read(key: _dbPassphraseKey);

  /// AC-13 — supprime toutes les clés Scalario du secure storage
  /// (passphrase perdue = DB supprimée + bootstrap forcé au prochain login).
  Future<void> clearAll() async {
    for (final String key in _allKeys) {
      try {
        await _storage.delete(key: key);
      } catch (e) {
        developer.log(
          'AuthStorage.clearAll: failed to delete $key: $e',
          name: 'Scalario.Offline.AuthStorage',
          level: 900,
        );
      }
    }
  }

  bool _safeEquals(
    String? a,
    String? b, {
    bool Function(String, String) compare = _defaultCompare,
  }) =>
      compare(a ?? '', b ?? '');

  bool containsKey(String key, String value) {
    if (key == _accessKey) return _safeEquals(value, _cachedAccess);
    if (key == _refreshKey) return _safeEquals(value, _cachedRefresh);
    if (key == _dbPassphraseKey) return _safeEquals(value, _cachedDbPassphrase);
    return false;
  }

  // Cache interne pour tests (pas de read depuis secure storage en test).
  String? _cachedAccess;
  String? _cachedRefresh;
  String? _cachedDbPassphrase;

  @visibleForTesting
  void setCacheForTesting({
    String? access,
    String? refresh,
    String? dbPassphrase,
  }) {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    _cachedDbPassphrase = dbPassphrase;
  }

  @visibleForTesting
  // ignore: avoid_public_notifier_properties
  String? get cachedAccess => _cachedAccess;
  @visibleForTesting
  // ignore: avoid_public_notifier_properties
  String? get cachedRefresh => _cachedRefresh;
  @visibleForTesting
  // ignore: avoid_public_notifier_properties
  String? get cachedDbPassphrase => _cachedDbPassphrase;

  static const String _accessKey = 'scalario.auth.access';
  static const String _refreshKey = 'scalario.auth.refresh';
  static const String _dbPassphraseKey = 'scalario.db.passphrase';

  static const List<String> _allKeys = [
    _accessKey,
    _refreshKey,
    _dbPassphraseKey,
  ];
}

bool _defaultCompare(String a, String b) => a == b;

// ignore: unused_element
void _noop() {}
