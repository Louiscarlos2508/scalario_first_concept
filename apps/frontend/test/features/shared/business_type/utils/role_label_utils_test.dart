import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/shared/business_type/utils/role_label_utils.dart';

void main() {
  group('getRoleLabel', () {
    test('owner always returns Propriétaire regardless of roleLabels', () {
      expect(getRoleLabel('owner', {}), equals('Propriétaire'));
      expect(
        getRoleLabel('owner', {'owner': 'Boss'}),
        equals('Propriétaire'),
      );
    });

    test('returns custom label when present in roleLabels', () {
      final labels = {'commercial': 'Vendeur', 'cashier': 'Caissière'};
      expect(getRoleLabel('commercial', labels), equals('Vendeur'));
      expect(getRoleLabel('cashier', labels), equals('Caissière'));
    });

    test('falls back to capitalised roleCode when key absent', () {
      expect(getRoleLabel('manager', {}), equals('Manager'));
      expect(getRoleLabel('commercial', {}), equals('Commercial'));
      expect(getRoleLabel('cashier', {}), equals('Cashier'));
    });

    test('falls back to capitalised roleCode when label is empty string', () {
      expect(getRoleLabel('commercial', {'commercial': ''}), equals('Commercial'));
    });

    test('returns empty string for empty roleCode', () {
      expect(getRoleLabel('', {}), equals(''));
    });

    test('ignores non-String values in roleLabels', () {
      expect(getRoleLabel('manager', {'manager': 42}), equals('Manager'));
    });
  });
}
