import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas_registry/unknown_component.dart';

void main() {
  group('UnknownComponent', () {
    testWidgets('renders warning message with the component type', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: UnknownComponent('MissingWidget')),
      ));

      expect(find.textContaining('MissingWidget'), findsOneWidget);
      expect(find.textContaining('indisponible'), findsOneWidget);
    });

    testWidgets('handles empty type string — shows fallback label', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: UnknownComponent('')),
      ));

      expect(find.textContaining('sans type'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('minimum height is 56dp', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: UnknownComponent('TestType')),
      ));

      final constrainedBox =
          tester.widget<ConstrainedBox>(find.byType(ConstrainedBox).first);

      expect(
        constrainedBox.constraints.minHeight,
        greaterThanOrEqualTo(56),
      );
    });

    testWidgets('never crashes regardless of type content', (tester) async {
      const types = ['', 'UnknownGadget', '123abc', 'a b c d'];
      for (final type in types) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: UnknownComponent(type)),
        ));
        expect(tester.takeException(), isNull,
            reason: 'Should not throw for type: "$type"');
      }
    });
  });
}
