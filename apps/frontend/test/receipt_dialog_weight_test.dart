import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/retail/pos/data/models/cart_item.dart';
import 'package:frontend/features/retail/pos/data/models/order.dart';
import 'package:frontend/features/retail/pos/presentation/widgets/receipt_dialog.dart';

void main() {
  group('ReceiptDialog — weight items (AC3, Epic 20)', () {
    Order buildOrder({required List<PosCartItem> items}) {
      final order = Order()
        ..uuid = '12345678-test-test-test-000000000000'
        ..totalAmount = items.fold(0.0, (s, i) => s + i.price * i.quantity)
        ..paymentMethod = 'CASH'
        ..createdAt = DateTime(2026, 3, 19);
      order.items = items;
      return order;
    }

    testWidgets('weight item shows qty + unit label, not "pièce(s)"', (
      tester,
    ) async {
      final item = PosCartItem()
        ..name = 'Tomates'
        ..quantity = 1.5
        ..price = 1500.0
        ..unitType = 'weight'
        ..unitLabel = 'kg'
        ..pricePerUnit = 1500.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReceiptDialog(
              order: buildOrder(items: [item]),
              tenantName: 'Test Shop',
            ),
          ),
        ),
      );

      // "1.5 kg" should appear
      expect(find.textContaining('1.5'), findsWidgets);
      expect(find.textContaining('kg'), findsWidgets);

      // Should NOT show "pièce(s)"
      expect(find.textContaining('pièce'), findsNothing);
    });

    testWidgets('weight item total displays 2 250 for 1.5 kg at 1500 F/kg', (
      tester,
    ) async {
      final item = PosCartItem()
        ..name = 'Tomates'
        ..quantity = 1.5
        ..price =
            1500.0 // unit price
        ..unitType = 'weight'
        ..unitLabel = 'kg'
        ..pricePerUnit = 1500.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReceiptDialog(
              order: buildOrder(items: [item]),
              tenantName: 'Test Shop',
            ),
          ),
        ),
      );

      // Total line = 1500 × 1.5 = 2250 → shown as "2 250"
      expect(find.textContaining('2\u202f250'), findsWidgets);
    });

    testWidgets('piece item shows integer quantity format', (tester) async {
      final item = PosCartItem()
        ..name = 'Coca-Cola'
        ..quantity = 3.0
        ..price = 500.0
        ..unitType = 'piece';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ReceiptDialog(
              order: buildOrder(items: [item]),
              tenantName: 'Test Shop',
            ),
          ),
        ),
      );

      expect(find.textContaining('x3'), findsWidgets);
    });
  });
}
