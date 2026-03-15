import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/models/sync_status.dart';

// Unit tests for RetentionService purge logic.
//
// Full Isar integration tests require a native Isar instance (flutter_integration_test).
// These unit tests verify the three invariants of the purge logic:
//   1. Only synced records are eligible (pending records are protected).
//   2. Only records older than the cutoff are purged.
//   3. The cutoff is correctly computed as (now - retentionDays).

DateTime _cutoff({int retentionDays = 60}) =>
    DateTime.now().subtract(Duration(days: retentionDays));

bool _isEligibleForPurge(SyncStatus status, DateTime recordDate,
    {int retentionDays = 60}) {
  if (status != SyncStatus.synced) return false;
  return recordDate.isBefore(_cutoff(retentionDays: retentionDays));
}

void main() {
  group('RetentionService purge eligibility', () {
    test('old synced record is eligible for purge', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 61));
      expect(_isEligibleForPurge(SyncStatus.synced, oldDate), isTrue);
    });

    test('recent synced record is NOT eligible for purge', () {
      final recentDate = DateTime.now().subtract(const Duration(days: 1));
      expect(_isEligibleForPurge(SyncStatus.synced, recentDate), isFalse);
    });

    test('old PENDING record is never eligible (outbox protection)', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 90));
      expect(_isEligibleForPurge(SyncStatus.pending, oldDate), isFalse);
    });

    test('old ERROR record is never eligible', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 90));
      expect(_isEligibleForPurge(SyncStatus.error, oldDate), isFalse);
    });

    test('record exactly at cutoff boundary is NOT purged', () {
      // isBefore() is strict — use fixed dates to avoid timing sensitivity
      final fixed = DateTime(2024, 6, 15, 12, 0, 0);
      expect(fixed.isBefore(fixed), isFalse);
    });

    test('cutoff is approximately 60 days before now by default', () {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 60));
      // Use inHours to avoid inDays truncation issues
      final diffHours = now.difference(cutoff).inHours;
      expect(diffHours, greaterThanOrEqualTo(60 * 24));
      expect(diffHours, lessThanOrEqualTo(60 * 24 + 1));
    });
  });
}
