/// STORY-042 — Date / time formatter.
///
/// Phase 1: self-contained Dart implementation (no `intl` dependency).
/// To be swapped for `intl.DateFormat.yMd(locale)` when `intl` lands.
/// Resolves the locale → date format pattern per BCP-47 region tag.
class DateFmt {
  DateFmt._();

  /// "DD/MM/YYYY" (FR, EU defaults) vs "M/D/YYYY" (US).
  static String yMd(DateTime date, String locale) {
    final lower = locale.toLowerCase();
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    if (lower.startsWith('en')) {
      // US-style: M/D/YYYY (no zero-pad on month/day).
      return '${date.month}/${date.day}/$y';
    }
    // FR + most EU / African Francophone locales.
    return '$d/$m/$y';
  }

  /// "HH:mm" — 24h universal (FR + en-GB + Africa standard).
  static String hm(DateTime date, String locale) {
    final lower = locale.toLowerCase();
    if (lower == 'en-us' || lower == 'en_us') {
      // US 12-hour. AM/PM.
      final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final ampm = date.hour < 12 ? 'AM' : 'PM';
      final m = date.minute.toString().padLeft(2, '0');
      return '$hour12:$m $ampm';
    }
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Relative-time helper for the SyncStatusBar / KPICard "last updated"
  /// strings. FR fallback if locale isn't en.
  static String relativePast(DateTime then, {DateTime? now, String locale = 'fr-BF'}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(then);
    final lower = locale.toLowerCase();
    final en = lower.startsWith('en');

    if (diff.inSeconds < 60) return en ? 'just now' : 'à l\'instant';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return en ? '$m min ago' : 'il y a $m min';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return en ? '$h h ago' : 'il y a $h h';
    }
    final d = diff.inDays;
    return en ? '$d d ago' : 'il y a $d j';
  }
}
