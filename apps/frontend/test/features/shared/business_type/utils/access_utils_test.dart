import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/shared/business_type/data/business_type_config_repository.dart';
import 'package:frontend/features/shared/business_type/utils/access_utils.dart';

// ── Helper : garantit Map<String,dynamic> profond (identique au vrai JSON) ────
BusinessTypeConfig _cfg(Map<String, Object> raw) =>
    BusinessTypeConfig.fromJson(
      jsonDecode(jsonEncode(raw)) as Map<String, dynamic>,
    );

// ── Configs de test ────────────────────────────────────────────────────────────

/// Épicerie : commercial a accès transfers + losses + stock_view + daily_sales.
final _configEpicerie = _cfg({
  'code': 'epicerie',
  'name': 'Épicerie',
  'defaultFlags': <String, Object>{},
  'visibleSections': ['transfers'],
  'suggestedCategories': <String>[],
  'roleScreenAccess': {
    'owner': ['backoffice', 'pos'],
    'manager': ['backoffice_restricted', 'clients_view', 'expenses'],
    'commercial': ['pos', 'losses', 'transfers', 'stock_view', 'daily_sales'],
    'cashier': ['pos'],
  },
});

/// Généraliste : commercial n'a PAS transfers.
final _configGeneraliste = _cfg({
  'code': 'generaliste',
  'name': 'Généraliste',
  'defaultFlags': <String, Object>{},
  'visibleSections': <String>[],
  'suggestedCategories': <String>[],
  'roleScreenAccess': {
    'owner': ['backoffice', 'pos'],
    'manager': ['backoffice_restricted', 'clients_view', 'expenses'],
    'commercial': ['pos', 'losses', 'stock_view', 'daily_sales'],
    'cashier': ['pos'],
  },
});

void main() {
  group('canAccessScreen — fallback (config null)', () {
    test('owner accède à backoffice', () {
      expect(canAccessScreen('owner', 'backoffice', null), isTrue);
    });

    test('cashier n\'accède pas à backoffice', () {
      expect(canAccessScreen('cashier', 'backoffice', null), isFalse);
    });

    test('commercial accède à losses', () {
      expect(canAccessScreen('commercial', 'losses', null), isTrue);
    });

    test('commercial accède à transfers', () {
      expect(canAccessScreen('commercial', 'transfers', null), isTrue);
    });

    test('cashier n\'accède pas à losses', () {
      expect(canAccessScreen('cashier', 'losses', null), isFalse);
    });

    test('rôle inconnu retourne false', () {
      expect(canAccessScreen('unknown_role', 'backoffice', null), isFalse);
    });
  });

  group('canAccessScreen — config épicerie', () {
    test('owner accède à backoffice', () {
      expect(canAccessScreen('owner', 'backoffice', _configEpicerie), isTrue);
    });

    test('manager accède à clients_view', () {
      expect(canAccessScreen('manager', 'clients_view', _configEpicerie), isTrue);
    });

    test('manager accède à expenses', () {
      expect(canAccessScreen('manager', 'expenses', _configEpicerie), isTrue);
    });

    test('commercial accède à transfers (épicerie)', () {
      expect(canAccessScreen('commercial', 'transfers', _configEpicerie), isTrue);
    });

    test('commercial accède à stock_view (épicerie)', () {
      expect(canAccessScreen('commercial', 'stock_view', _configEpicerie), isTrue);
    });

    test('cashier n\'accède pas à losses (épicerie)', () {
      expect(canAccessScreen('cashier', 'losses', _configEpicerie), isFalse);
    });
  });

  group('canAccessScreen — config généraliste', () {
    test('commercial n\'accède PAS à transfers (généraliste)', () {
      expect(canAccessScreen('commercial', 'transfers', _configGeneraliste), isFalse);
    });

    test('manager accède à backoffice_restricted (généraliste)', () {
      expect(canAccessScreen('manager', 'backoffice_restricted', _configGeneraliste), isTrue);
    });

    test('manager n\'accède pas à backoffice (généraliste, restreint)', () {
      expect(canAccessScreen('manager', 'backoffice', _configGeneraliste), isFalse);
    });
  });

  group('canAccessScreen — BusinessTypeConfig.fallback', () {
    test('équivalent config null pour owner/backoffice', () {
      final withNull = canAccessScreen('owner', 'backoffice', null);
      final withFallback = canAccessScreen('owner', 'backoffice', BusinessTypeConfig.fallback);
      expect(withNull, equals(withFallback));
    });

    test('équivalent config null pour cashier/pos', () {
      final withNull = canAccessScreen('cashier', 'pos', null);
      final withFallback = canAccessScreen('cashier', 'pos', BusinessTypeConfig.fallback);
      expect(withNull, equals(withFallback));
    });
  });
}
