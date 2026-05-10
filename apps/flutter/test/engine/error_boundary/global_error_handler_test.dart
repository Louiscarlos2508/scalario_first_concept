import 'dart:async';

import 'package:flutter/foundation.dart'
    show FlutterError, FlutterErrorDetails, PlatformDispatcher;
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/error_boundary/error_logger.dart';
import 'package:scalario/engine/error_boundary/global_error_handler.dart';

void main() {
  setUp(() => ErrorLogger.instance.clear());

  group('AC-09 — GlobalErrorHandler.install wires FlutterError.onError', () {
    test('FlutterError.onError logs via ErrorLogger after install', () {
      final prevOnError = FlutterError.onError;
      GlobalErrorHandler.install();

      FlutterError.reportError(FlutterErrorDetails(
        exception: Exception('flutter framework error'),
        stack: StackTrace.empty,
        library: 'test',
      ));

      expect(ErrorLogger.instance.recentErrors, hasLength(1));
      expect(
        ErrorLogger.instance.recentErrors.first.errorType,
        contains('Exception'),
      );

      // Restore to avoid polluting other tests
      FlutterError.onError = prevOnError;
    });
  });

  group('AC-10 — handleZoneError logs the error', () {
    test('handleZoneError logs exception to ErrorLogger', () {
      GlobalErrorHandler.handleZoneError(
        Exception('async zone error'),
        StackTrace.empty,
      );

      expect(ErrorLogger.instance.recentErrors, hasLength(1));
      expect(
        ErrorLogger.instance.recentErrors.first.componentType,
        'global',
      );
    });

    test('handleZoneError does not throw', () {
      expect(
        () => GlobalErrorHandler.handleZoneError(
          Exception('safe'),
          StackTrace.empty,
        ),
        returnsNormally,
      );
    });
  });

  group('AC-18 scenario 4 — async exception is caught by runZonedGuarded', () {
    test('unhandled async error in zone is logged, no crash', () async {
      final errors = <Object>[];

      await runZonedGuarded(
        () async {
          // Fire-and-forget Future that rejects
          unawaited(Future<void>.error(
            Exception('orphan async error'),
            StackTrace.empty,
          ));
          // Give the zone a chance to catch it
          await Future<void>.delayed(Duration.zero);
        },
        (error, stack) {
          errors.add(error);
          GlobalErrorHandler.handleZoneError(error, stack);
        },
      );

      expect(errors, hasLength(1));
      expect(ErrorLogger.instance.recentErrors, hasLength(1));
    });
  });

  group('PlatformDispatcher.onError — install returns true', () {
    test('install sets PlatformDispatcher.onError and it returns true', () {
      final prevOnError = FlutterError.onError;
      GlobalErrorHandler.install();

      final bool result = PlatformDispatcher.instance.onError!(
        Exception('platform error'),
        StackTrace.empty,
      );

      expect(result, isTrue); // prevents platform from crashing isolate
      expect(ErrorLogger.instance.recentErrors, isNotEmpty);

      FlutterError.onError = prevOnError;
    });
  });
}
