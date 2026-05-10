import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/error_boundary/error_logger.dart';
import 'package:scalario/engine/error_boundary/error_payload.dart';

ErrorPayload _makePayload({String type = 'KPICard', String id = 'k1'}) =>
    ErrorPayload(
      error: Exception('test error'),
      stack: StackTrace.empty,
      componentType: type,
      componentId: id,
    );

void main() {
  group('ErrorLogger — ring buffer (AC-13)', () {
    test('log adds entry to recentErrors', () {
      final logger = ErrorLogger.forTesting();
      logger.log(_makePayload());
      expect(logger.recentErrors, hasLength(1));
    });

    test('recentErrors is ordered oldest→newest', () {
      final logger = ErrorLogger.forTesting(capacity: 5);
      logger.log(_makePayload(id: 'first'));
      logger.log(_makePayload(id: 'second'));
      expect(logger.recentErrors.first.componentId, 'first');
      expect(logger.recentErrors.last.componentId, 'second');
    });

    test('exceeding capacity drops oldest entry', () {
      final logger = ErrorLogger.forTesting(capacity: 3);
      logger.log(_makePayload(id: 'a'));
      logger.log(_makePayload(id: 'b'));
      logger.log(_makePayload(id: 'c'));
      logger.log(_makePayload(id: 'd')); // drops 'a'

      expect(logger.length, 3);
      expect(logger.recentErrors.map((e) => e.componentId),
          containsAll(['b', 'c', 'd']));
      expect(logger.recentErrors.map((e) => e.componentId),
          isNot(contains('a')));
    });

    test('clear empties the buffer (AC-17)', () {
      final logger = ErrorLogger.forTesting();
      logger.log(_makePayload());
      logger.log(_makePayload());
      logger.clear();
      expect(logger.recentErrors, isEmpty);
    });

    test('recentErrors returns an unmodifiable view', () {
      final logger = ErrorLogger.forTesting();
      logger.log(_makePayload());
      expect(
        () => logger.recentErrors.add(_makePayload()),
        throwsUnsupportedError,
      );
    });
  });

  group('ErrorLogger — never crashes on bad input', () {
    test('log with empty stack does not throw', () {
      final logger = ErrorLogger.forTesting();
      expect(
        () => logger.log(_makePayload()),
        returnsNormally,
      );
    });

    test('log successive identical errors adds multiple entries', () {
      final logger = ErrorLogger.forTesting();
      for (var i = 0; i < 5; i++) {
        logger.log(_makePayload());
      }
      expect(logger.length, 5);
    });
  });

  group('ErrorPayload — sanitization (AC-15, AC-16)', () {
    test('email stripped from message', () {
      final p = ErrorPayload(
        error: Exception('token for admin@scalario.com expired'),
        stack: StackTrace.empty,
        componentType: 'Auth',
      );
      expect(p.message, isNot(contains('@')));
      expect(p.message, contains('[email]'));
    });

    test('7-digit number stripped', () {
      final p = ErrorPayload(
        error: Exception('ref 1234567 not found'),
        stack: StackTrace.empty,
        componentType: 'POS',
      );
      expect(p.message, isNot(contains('1234567')));
      expect(p.message, contains('[number]'));
    });

    test('short numbers (< 7 digits) are not stripped', () {
      final p = ErrorPayload(
        error: Exception('index 42 out of bounds'),
        stack: StackTrace.empty,
        componentType: 'Table',
      );
      expect(p.message, contains('42'));
    });

    test('public sanitize API exposes the same logic', () {
      const raw = 'User test@demo.io sent 9999999 FCFA';
      final result = ErrorPayload.sanitize(raw);
      expect(result, isNot(contains('@')));
      expect(result, isNot(contains('9999999')));
    });
  });

  group('ErrorPayload — toJson schema (AC-11)', () {
    test('contains all required keys', () {
      final p = ErrorPayload(
        error: Exception('test'),
        stack: StackTrace.empty,
        componentType: 'KPICard',
        componentId: 'kpi_1',
        screenId: 'retail_dashboard',
        tenantId: 'tenant-uuid',
        userId: 'user-uuid',
      );
      final Map<String, dynamic> json = p.toJson();

      expect(json, containsPair('ts', isA<String>()));
      expect(json, containsPair('level', 'error'));
      expect(json, containsPair('tenant_id', 'tenant-uuid'));
      expect(json, containsPair('user_id', 'user-uuid'));
      expect(json, containsPair('screen_id', 'retail_dashboard'));
      expect(json, containsPair('component_type', 'KPICard'));
      expect(json, containsPair('component_id', 'kpi_1'));
      expect(json['error_type'].toString(), contains('Exception'));
      expect(json, containsPair('stack_hash', isA<String>()));
      expect(json, containsPair('app_version', isA<String>()));
      expect(json, containsPair('platform', isA<String>()));
    });

    test('stack_hash is 8 hex chars', () {
      final p = ErrorPayload(
        error: Exception('x'),
        stack: StackTrace.empty,
        componentType: 'X',
      );
      expect(p.stackHash, matches(RegExp(r'^[0-9a-f]{8}$')));
    });

    test('two identical stacks produce the same hash', () {
      const trace = StackTrace.empty;
      final p1 = ErrorPayload(
          error: Exception('a'), stack: trace, componentType: 'X');
      final p2 = ErrorPayload(
          error: Exception('b'), stack: trace, componentType: 'Y');
      expect(p1.stackHash, equals(p2.stackHash));
    });
  });
}
