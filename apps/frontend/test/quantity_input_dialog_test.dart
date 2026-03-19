import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/retail/pos/data/models/product.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/quantity_input_dialog.dart';

void main() {
  Product _buildWeightProduct({
    String name = 'Tomates',
    double price = 1500.0,
    double? pricePerUnit,
    String unitType = 'weight',
    String? weightUnit = 'kg',
  }) {
    return Product()
      ..name = name
      ..price = price
      ..pricePerUnit = pricePerUnit
      ..unitType = unitType
      ..weightUnit = weightUnit;
  }

  group('QuantityInputDialog — AC7, AC4 (Epic 20)', () {
    testWidgets('confirms entered quantity and pops with the double value',
        (tester) async {
      double? poppedQty;

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              poppedQty = await showDialog<double>(
                context: context,
                builder: (_) =>
                    QuantityInputDialog(product: _buildWeightProduct()),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('quantity_input_field')), '2.3');
      await tester.tap(find.byKey(const Key('quantity_confirm_button')));
      await tester.pumpAndSettle();

      expect(poppedQty, 2.3);
    });

    testWidgets('rejects zero quantity and shows validation error',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: QuantityInputDialog(product: _buildWeightProduct()),
      ));

      await tester.enterText(
          find.byKey(const Key('quantity_input_field')), '0');
      await tester.tap(find.byKey(const Key('quantity_confirm_button')));
      await tester.pump();

      expect(find.text('Doit être > 0'), findsOneWidget);
    });

    testWidgets('rejects empty quantity', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: QuantityInputDialog(product: _buildWeightProduct()),
      ));

      await tester.tap(find.byKey(const Key('quantity_confirm_button')));
      await tester.pump();

      expect(find.text('Obligatoire'), findsOneWidget);
    });
  });

  group('FCFA rounding — AC4 (Epic 20)', () {
    double roundToNearest5(double amount) => (amount / 5).round() * 5.0;

    test('1 333 × 0.75 = 999.75 → rounds to 1 000', () {
      expect(roundToNearest5(1333 * 0.75), equals(1000.0));
    });

    test('1 500 × 1.5 = 2 250 → no rounding needed', () {
      expect(roundToNearest5(1500 * 1.5), equals(2250.0));
    });

    test('1 100 × 0.3 = 330 → already a multiple of 5', () {
      expect(roundToNearest5(1100 * 0.3), equals(330.0));
    });

    test('1 000 × 1.0 = 1 000 → no rounding', () {
      expect(roundToNearest5(1000 * 1.0), equals(1000.0));
    });
  });
}
