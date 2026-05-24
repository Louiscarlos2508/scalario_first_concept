/// STORY-042 — Currency formatter.
///
/// Phase 1: self-contained Dart implementation (no `intl` dependency yet
/// — to be swapped for `intl.NumberFormat.currency` when the package is
/// added). Resolves the symbol from a per-tenant currency code via a
/// minimal map; unknown codes echo the ISO 4217 string.
///
/// Global-scale rule (NFR-010): the symbol must come from tenant config,
/// never from hardcoded literals in widgets. The helper enforces this by
/// requiring the [TenantCurrencyContext] object — there's no string-only
/// override.
class TenantCurrencyContext {
  const TenantCurrencyContext({
    required this.currencyCode,
    required this.locale,
  });

  /// ISO 4217 code (e.g. "XOF", "EUR", "USD").
  final String currencyCode;

  /// IETF BCP-47 locale (e.g. "fr-BF", "en-US").
  final String locale;
}

/// Symbol map. Kept minimal — Phase 2 will use `intl` for the full
/// CLDR-backed table.
const Map<String, String> _kSymbols = {
  'XOF': 'FCFA',
  'XAF': 'FCFA',
  'EUR': '€',
  'USD': '\$',
  'GBP': '£',
  'NGN': '₦',
  'GHS': 'GH₵',
};

/// Helper class wrapping the formatting logic. Static-style API.
class Currency {
  Currency._();

  /// Returns the human-readable symbol for [currencyCode], falling back
  /// to the code itself if unknown.
  static String symbolFor(String currencyCode) =>
      _kSymbols[currencyCode.toUpperCase()] ?? currencyCode.toUpperCase();

  /// Whether the locale prefers the symbol AFTER the number (FR, common
  /// in West Africa) or BEFORE (US, en-GB for £).
  static bool _symbolFollows(String locale, String code) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('en') && (code == 'USD' || code == 'GBP')) {
      return false;
    }
    if (code == 'EUR' && lower.startsWith('en')) return false;
    // Default: symbol follows (FR, fr-BF, fr-CI etc.).
    return true;
  }

  /// Whether the locale uses a comma decimal separator.
  static bool _commaDecimal(String locale) =>
      locale.toLowerCase().startsWith('fr');

  /// Formats [amount] for [tenant], inserting a non-breaking space as
  /// the thousands separator for FR locales (per the DS spec: monetary
  /// values render in Roboto Mono with `12 500 FCFA`).
  static String format(num amount, TenantCurrencyContext tenant) {
    final symbol = symbolFor(tenant.currencyCode);
    final isInteger = amount == amount.truncateToDouble();
    final commaDecimal = _commaDecimal(tenant.locale);
    final groupSep = commaDecimal
        ? ' ' // non-breaking space (FR thousands)
        : ',';
    final decimalSep = commaDecimal ? ',' : '.';

    final wholeStr = amount.abs().truncate().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < wholeStr.length; i++) {
      if (i > 0 && (wholeStr.length - i) % 3 == 0) grouped.write(groupSep);
      grouped.write(wholeStr[i]);
    }

    var formatted = grouped.toString();
    if (!isInteger) {
      final fracStr =
          (amount.abs() - amount.abs().truncate()).toStringAsFixed(2).substring(2);
      formatted = '$formatted$decimalSep$fracStr';
    }
    if (amount < 0) formatted = '-$formatted';

    return _symbolFollows(tenant.locale, tenant.currencyCode.toUpperCase())
        ? '$formatted $symbol'
        : '$symbol$formatted';
  }
}
