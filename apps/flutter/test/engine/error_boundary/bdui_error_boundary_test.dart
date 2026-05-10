import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/error_boundary/bdui_error_boundary.dart';
import 'package:scalario/engine/error_boundary/error_logger.dart';
import 'package:scalario/engine/error_boundary/error_screen.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

class _ThrowingWidget extends StatelessWidget {
  const _ThrowingWidget();
  @override
  Widget build(BuildContext context) =>
      throw const BDUIValidationException("missing 'title'", jsonPath: 'components[0]');
}

void Function() _muteFlutterErrors() {
  final prev = FlutterError.onError;
  FlutterError.onError = (_) {};
  return () => FlutterError.onError = prev;
}

void main() {
  setUp(() => ErrorLogger.instance.clear());

  group('AC-06/AC-07 — BDUIErrorBoundary catches screen-level exception', () {
    testWidgets('throwing child → BDUIErrorScreen rendered', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        const BDUIErrorBoundary(
          screenId: 'retail_dashboard',
          child: _ThrowingWidget(),
        ),
      ));
      await tester.pump();

      restore();
      expect(find.byType(BDUIErrorScreen), findsOneWidget);
    });

    testWidgets('error is logged with screenId', (tester) async {
      final restore = _muteFlutterErrors();

      await tester.pumpWidget(_wrap(
        const BDUIErrorBoundary(
          screenId: 'retail_dashboard',
          child: _ThrowingWidget(),
        ),
      ));
      await tester.pump();

      restore();
      expect(ErrorLogger.instance.recentErrors, hasLength(1));
      expect(
        ErrorLogger.instance.recentErrors.first.screenId,
        'retail_dashboard',
      );
    });

    testWidgets('healthy child renders without BDUIErrorScreen', (tester) async {
      await tester.pumpWidget(_wrap(
        const BDUIErrorBoundary(
          screenId: 'ok_screen',
          child: Text('screen OK'),
        ),
      ));

      expect(find.text('screen OK'), findsOneWidget);
      expect(find.byType(BDUIErrorScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('AC-08 — retry button clears error state (AC-18 scenario 3)', () {
    testWidgets('tapping Réessayer calls onRetry and hides BDUIErrorScreen',
        (tester) async {
      final restore = _muteFlutterErrors();
      bool retryCalled = false;

      // We use a ValueNotifier to toggle throwing/healthy after retry.
      final notifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(_wrap(
        ValueListenableBuilder<bool>(
          valueListenable: notifier,
          builder: (_, shouldThrow, _) => BDUIErrorBoundary(
            screenId: 'test_screen',
            onRetry: () {
              retryCalled = true;
              notifier.value = false; // switch to healthy after retry
            },
            child: shouldThrow
                ? const _ThrowingWidget()
                : const Text('screen recovered'),
          ),
        ),
      ));
      await tester.pump(); // post-frame setState → BDUIErrorScreen visible

      restore();
      expect(find.byType(BDUIErrorScreen), findsOneWidget);

      // Tap "Réessayer"
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      await tester.pump();

      expect(retryCalled, isTrue);
      expect(find.byType(BDUIErrorScreen), findsNothing);
      expect(find.text('screen recovered'), findsOneWidget);
    });
  });

  group('BDUIValidationException', () {
    test('toString includes message and jsonPath', () {
      const e = BDUIValidationException('bad field', jsonPath: 'components[0]');
      expect(e.toString(), contains('bad field'));
      expect(e.toString(), contains('components[0]'));
    });

    test('toString without jsonPath omits "at"', () {
      const e = BDUIValidationException('missing title');
      expect(e.toString(), isNot(contains(' at ')));
    });
  });

  group('BDUIRenderException', () {
    test('toString includes message', () {
      const e = BDUIRenderException('layout failed');
      expect(e.toString(), contains('layout failed'));
    });
  });
}
