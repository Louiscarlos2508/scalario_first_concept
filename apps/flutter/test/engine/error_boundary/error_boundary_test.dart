import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/error_boundary/error_boundary.dart';
import 'package:scalario/engine/error_boundary/error_fallback.dart';
import 'package:scalario/engine/error_boundary/error_logger.dart';
import 'package:scalario/engine/error_boundary/error_payload.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

/// Simulates a widget that throws synchronously during build.
class _ThrowingWidget extends StatelessWidget {
  const _ThrowingWidget({this.message = 'build error'});
  final String message;
  @override
  Widget build(BuildContext context) => throw Exception(message);
}

class _OkWidget extends StatelessWidget {
  const _OkWidget({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Text(label);
}

/// Captures FlutterError without failing the test, returns a restore function.
void Function() _muteFlutterErrors() {
  final prev = FlutterError.onError;
  FlutterError.onError = (_) {};
  return () => FlutterError.onError = prev;
}

void main() {
  // Share a test-scoped logger so that tests don't pollute each other via
  // the singleton. We clear the singleton buffer in setUp.
  setUp(() => ErrorLogger.instance.clear());

  group('AC-01/AC-03 — ErrorBoundary props and default fallback', () {
    testWidgets('healthy child renders normally', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorBoundary(
          componentType: 'KPICard',
          componentId: 'kpi_1',
          child: Text('OK'),
        ),
      ));
      expect(find.text('OK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('custom fallbackBuilder is used when provided', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        ErrorBoundary(
          componentType: 'KPICard',
          fallbackBuilder: (_, _, _) => const Text('custom fallback'),
          child: const _ThrowingWidget(),
        ),
      ));
      await tester.pump(); // let addPostFrameCallback fire

      restore();
      expect(find.text('custom fallback'), findsOneWidget);
    });
  });

  group('AC-02/AC-03 — ErrorBoundary catches build exception → shows fallback', () {
    testWidgets('throwing widget → ErrorFallback rendered', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        const ErrorBoundary(
          componentType: 'KPICard',
          componentId: 'kpi_test',
          child: _ThrowingWidget(),
        ),
      ));
      await tester.pump(); // post-frame setState

      restore();
      expect(find.byType(ErrorFallback), findsOneWidget);
    });

    testWidgets('error is logged to ErrorLogger ring buffer', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        const ErrorBoundary(
          componentType: 'KPICard',
          componentId: 'kpi_test',
          child: _ThrowingWidget(),
        ),
      ));
      await tester.pump();

      restore();
      expect(ErrorLogger.instance.recentErrors, hasLength(1));
      final ErrorPayload payload = ErrorLogger.instance.recentErrors.first;
      expect(payload.componentType, 'KPICard');
      expect(payload.componentId, 'kpi_test');
      expect(payload.errorType, contains('Exception'));
    });
  });

  group('AC-04 — ErrorFallback minimum height 56dp', () {
    testWidgets('fallback respects minHeight constraint', (tester) async {
      await tester.pumpWidget(_wrap(
        const ErrorFallback(componentType: 'KPICard'),
      ));
      final Size size = tester.getSize(find.byType(ErrorFallback));
      expect(size.height, greaterThanOrEqualTo(56));
    });
  });

  group('AC-18 scenario 2 — 5 side-by-side components, only 3rd fails', () {
    testWidgets('only the failing component shows ErrorFallback', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        Row(
          children: List<Widget>.generate(5, (i) {
            final Widget child = (i == 2)
                ? const _ThrowingWidget()
                : _OkWidget(label: 'kpi$i');
            return Expanded(
              child: ErrorBoundary(
                componentType: 'KPICard',
                componentId: 'kpi_$i',
                child: child,
              ),
            );
          }),
        ),
      ));
      await tester.pump();

      restore();

      // Exactly one ErrorFallback
      expect(find.byType(ErrorFallback), findsOneWidget);
      // Other four render their text
      for (final label in ['kpi0', 'kpi1', 'kpi3', 'kpi4']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('only the failing component is logged', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        Row(
          children: List<Widget>.generate(5, (i) {
            final Widget child = (i == 2)
                ? const _ThrowingWidget()
                : _OkWidget(label: 'ok$i');
            return Expanded(
              child: ErrorBoundary(
                componentType: 'KPICard',
                componentId: 'kpi_$i',
                child: child,
              ),
            );
          }),
        ),
      ));
      await tester.pump();

      restore();
      expect(ErrorLogger.instance.recentErrors, hasLength(1));
      expect(ErrorLogger.instance.recentErrors.first.componentId, 'kpi_2');
    });
  });

  group('AC-05 — custom fallbackBuilder receives error and stack', () {
    testWidgets('fallbackBuilder receives non-null error', (tester) async {
      final restore = _muteFlutterErrors();
      Object? capturedError;

      await tester.pumpWidget(_wrap(
        ErrorBoundary(
          componentType: 'DataTable',
          fallbackBuilder: (_, error, _) {
            capturedError = error;
            return const SizedBox.shrink();
          },
          child: const _ThrowingWidget(message: 'table error'),
        ),
      ));
      await tester.pump();

      restore();
      expect(capturedError, isNotNull);
      expect(capturedError.toString(), contains('table error'));
    });
  });

  group('AC-15/AC-19 — no PII in error logs', () {
    test('message with email is sanitized', () {
      final payload = ErrorPayload(
        error: Exception('User blandine@scalario.com failed auth'),
        stack: StackTrace.empty,
        componentType: 'LoginForm',
      );
      expect(payload.message, isNot(contains('@')));
      expect(payload.message, contains('[email]'));
    });

    test('message with 7-digit number is sanitized', () {
      final payload = ErrorPayload(
        error: Exception('Amount 1234567 FCFA exceeded'),
        stack: StackTrace.empty,
        componentType: 'POS',
      );
      expect(payload.message, isNot(contains('1234567')));
      expect(payload.message, contains('[number]'));
    });

    testWidgets('thrown message with email does not appear in log', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        const ErrorBoundary(
          componentType: 'Form',
          child: _ThrowingWidget(message: 'mock.user@test.example.com token invalid'),
        ),
      ));
      await tester.pump();

      restore();

      final List<ErrorPayload> errors = ErrorLogger.instance.recentErrors;
      expect(errors, hasLength(1));
      expect(errors.first.message, isNot(contains('@')));
      expect(errors.first.message, contains('[email]'));
    });
  });
}
