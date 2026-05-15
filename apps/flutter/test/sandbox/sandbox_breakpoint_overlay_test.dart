import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/sandbox/sandbox_breakpoint_overlay.dart';

void main() {
  testWidgets('SandboxBreakpointOverlay overrides MediaQuery size',
      (WidgetTester tester) async {
    Size? observed;
    await tester.pumpWidget(
      MaterialApp(
        home: SandboxBreakpointOverlay(
          breakpoint: SandboxBreakpoint.mobile,
          child: Builder(
            builder: (BuildContext ctx) {
              observed = MediaQuery.of(ctx).size;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(observed, const Size(360, 740));
  });
}
