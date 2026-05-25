import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/sync/retry_policy.dart';

void main() {
  late RetryPolicy policy;

  setUp(() {
    policy = RetryPolicy();
  });

  test('retry 0 → 1 second', () {
    expect(policy.nextBackoff(0), const Duration(seconds: 1));
  });

  test('retry 1 → 2 seconds', () {
    expect(policy.nextBackoff(1), const Duration(seconds: 2));
  });

  test('retry 2 → 4 seconds', () {
    expect(policy.nextBackoff(2), const Duration(seconds: 4));
  });

  test('retry 3 → 8 seconds', () {
    expect(policy.nextBackoff(3), const Duration(seconds: 8));
  });

  test('retry 4 → 16 seconds', () {
    expect(policy.nextBackoff(4), const Duration(seconds: 16));
  });

  test('retry 5 → 32 seconds', () {
    expect(policy.nextBackoff(5), const Duration(seconds: 32));
  });

  test('retry 10 → 1024 seconds', () {
    expect(policy.nextBackoff(10), const Duration(seconds: 1024));
  });

  test('retry 11 → capped at 1800 seconds', () {
    expect(policy.nextBackoff(11), const Duration(seconds: 1800));
  });

  test('retry 12 → still capped at 1800 seconds', () {
    expect(policy.nextBackoff(12), const Duration(seconds: 1800));
  });

  test('retry 100 → still capped at 1800 seconds', () {
    expect(policy.nextBackoff(100), const Duration(seconds: 1800));
  });
}
