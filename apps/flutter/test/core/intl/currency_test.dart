import 'package:flutter_test/flutter_test.dart';

import 'package:scalario/core/intl/currency.dart';

void main() {
  group('STORY-042 AC-08 — Currency.format', () {
    const blandineBf = TenantCurrencyContext(currencyCode: 'XOF', locale: 'fr-BF');
    const burkinaCi = TenantCurrencyContext(currencyCode: 'XOF', locale: 'fr-CI');
    const europeFr = TenantCurrencyContext(currencyCode: 'EUR', locale: 'fr-FR');
    const usUsd = TenantCurrencyContext(currencyCode: 'USD', locale: 'en-US');

    // U+00A0 (NBSP) used as the FR thousands separator + before the symbol,
    // per the DS spec ("12 500 FCFA" rendered in Roboto Mono).
    const nbsp = ' ';

    test('XOF in fr-BF → "12 500 FCFA" with non-breaking space', () {
      expect(Currency.format(12500, blandineBf), '12${nbsp}500${nbsp}FCFA');
    });

    test('XOF symbol resolves the same across French locales', () {
      expect(Currency.format(1000, burkinaCi), '1${nbsp}000${nbsp}FCFA');
    });

    test('EUR in fr-FR uses € symbol AFTER the number', () {
      expect(Currency.format(2500, europeFr), '2${nbsp}500$nbsp€');
    });

    test('USD in en-US uses \$ BEFORE with comma thousands', () {
      expect(Currency.format(2500, usUsd), '\$2,500');
    });

    test('decimal amounts render with the locale separator', () {
      expect(Currency.format(1234.56, europeFr), '1${nbsp}234,56$nbsp€');
      expect(Currency.format(1234.56, usUsd), '\$1,234.56');
    });

    test('negative amounts get a leading minus sign', () {
      expect(Currency.format(-500, blandineBf), '-500${nbsp}FCFA');
    });

    test('unknown currency code echoes itself uppercased', () {
      const fakeCtx = TenantCurrencyContext(currencyCode: 'zzz', locale: 'fr-BF');
      expect(Currency.format(100, fakeCtx), '100${nbsp}ZZZ');
    });

    test('symbolFor returns FCFA for both XOF and XAF (CFA franc union)', () {
      expect(Currency.symbolFor('XOF'), 'FCFA');
      expect(Currency.symbolFor('XAF'), 'FCFA');
    });

    test('global-scale: a tenant override changes the entire rendering', () {
      // The whole point of NFR-010 — symbol comes from tenant, not from
      // a literal in the codebase. Switch tenant config → output flips.
      // NGN: ₦ symbol follows the number by default (non-USD/GBP/EUR rule).
      const ngnCtx = TenantCurrencyContext(currencyCode: 'NGN', locale: 'en-US');
      expect(Currency.format(50000, ngnCtx), '50,000$nbsp₦');
      const ngnFrCtx = TenantCurrencyContext(currencyCode: 'NGN', locale: 'fr-BF');
      expect(Currency.format(50000, ngnFrCtx), '50${nbsp}000$nbsp₦');
    });
  });
}
