// STORY-009 — Sandbox dev-only (kDebugMode).
//
// Fournit un [UserContext] mutable en runtime pour tester les règles
// `visible_if` sans relancer l'app. 5 presets + mode custom JSON.

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../engine/bdui_engine/user_context_provider.dart';
import '../engine/rule_evaluator/user_context.dart';

/// Presets de rôles BDUI pour la sandbox (AC-04).
enum SandboxUserPreset {
  owner('OWNER'),
  admin('ADMIN'),
  manager('MANAGER'),
  cashier('CASHIER'),
  cashierLimited('CASHIER_LIMITED'),
  custom('Custom JSON');

  const SandboxUserPreset(this.label);
  final String label;
}

/// `UserContextProvider` mutable utilisé par le sandbox.
///
/// Diffère du `DemoUserContextProvider` de production : ses presets peuvent
/// changer en runtime pour tester les règles `visible_if` (AC-17, AC-19).
class SandboxUserContextProvider extends ChangeNotifier
    implements UserContextProvider {
  SandboxUserContextProvider({
    SandboxUserPreset preset = SandboxUserPreset.owner,
  })  : _preset = preset,
        _current = _ctxFromPreset(preset);

  static const String _tenantId = 'sandbox-tenant';
  static const String _userId = 'sandbox-user';

  SandboxUserPreset _preset;
  UserContext _current;
  String? _customError;

  SandboxUserPreset get preset => _preset;
  String? get customError => _customError;

  @override
  UserContext get current => _current;

  /// Bascule sur un preset standard (OWNER, ADMIN, ...).
  void selectPreset(SandboxUserPreset preset) {
    if (preset == SandboxUserPreset.custom) {
      _preset = preset;
      _customError = 'Saisissez un JSON UserContext';
      notifyListeners();
      return;
    }
    _preset = preset;
    _customError = null;
    _current = _ctxFromPreset(preset);
    notifyListeners();
  }

  /// Parse un JSON `{ "roles": [...], "departmentId": "...", ... }` (AC-18).
  /// Met à jour `_customError` au lieu de throw — l'UI affiche le message.
  void applyCustomJson(String raw) {
    _preset = SandboxUserPreset.custom;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _customError = 'Le JSON doit être un objet';
        notifyListeners();
        return;
      }
      final Object? rolesRaw = decoded['roles'];
      if (rolesRaw is! List || rolesRaw.isEmpty) {
        _customError = 'Champ "roles" requis (liste non vide)';
        notifyListeners();
        return;
      }
      _current = UserContext(
        userId: (decoded['userId'] as String?) ?? _userId,
        tenantId: (decoded['tenantId'] as String?) ?? _tenantId,
        roles: rolesRaw.whereType<String>().toSet(),
        departmentId: decoded['departmentId'] as String?,
      );
      _customError = null;
      notifyListeners();
    } on FormatException catch (e) {
      _customError = 'JSON invalide: ${e.message}';
      notifyListeners();
    }
  }

  static UserContext _ctxFromPreset(SandboxUserPreset preset) {
    final String role = switch (preset) {
      SandboxUserPreset.owner => 'OWNER',
      SandboxUserPreset.admin => 'ADMIN',
      SandboxUserPreset.manager => 'MANAGER',
      SandboxUserPreset.cashier => 'CASHIER',
      SandboxUserPreset.cashierLimited => 'CASHIER_LIMITED',
      SandboxUserPreset.custom => 'OWNER',
    };
    return UserContext(
      userId: _userId,
      tenantId: _tenantId,
      roles: <String>{role},
    );
  }
}
