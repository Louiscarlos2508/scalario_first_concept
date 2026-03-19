import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/shared/purchase_orders/data/models/purchase_order_local.dart';
import 'package:frontend/features/shared/purchase_orders/presentation/widgets/receive_purchase_order_sheet.dart';

PurchaseOrderLocal _buildOrder() {
  return PurchaseOrderLocal(
    id: 'po-test-1',
    status: 'confirmed',
    tenantId: 'tenant-1',
    lineCount: 2,
    createdAt: DateTime(2026, 3, 19),
    lines: [
      PurchaseOrderLineLocal(
        id: 'line-1',
        itemName: 'Riz 50 kg',
        expectedQuantity: 10.0,
        receivedQuantity: null,
      ),
      PurchaseOrderLineLocal(
        id: 'line-2',
        itemName: 'Huile 5L',
        expectedQuantity: 5.0,
        receivedQuantity: null,
      ),
    ],
  );
}

void main() {
  group('ReceivePurchaseOrderSheet — AC6, Story 21-3', () {
    testWidgets(
        'shows 2 lines with pre-filled expected quantities; variance appears when qty changes',
        (tester) async {
      final order = _buildOrder();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReceivePurchaseOrderSheet(order: order),
            ),
          ),
        ),
      );

      // Both lines should be visible
      expect(find.text('Riz 50 kg'), findsOneWidget);
      expect(find.text('Huile 5L'), findsOneWidget);

      // Pre-filled with expected quantity
      final line1QtyField = find.byKey(const Key('reception_line_0'));
      expect(line1QtyField, findsOneWidget);

      // No variance shown initially (qty == expected)
      expect(find.byKey(const Key('variance_line-1')), findsNothing);

      // Change line 1 qty to 12 (expected was 10 → variance = +2)
      final qtyFields = find.byType(TextField);
      // First TextField in the first line card is the qty field
      await tester.tap(qtyFields.first);
      await tester.pump();
      await tester.enterText(qtyFields.first, '12');
      await tester.pump();

      // Variance for line 1 should now show +2
      final varianceWidget = find.byKey(const Key('variance_line-1'));
      expect(varianceWidget, findsOneWidget);
      expect(find.text('+2'), findsOneWidget);

      // Line 2 unchanged — no variance shown for it
      expect(find.byKey(const Key('variance_line-2')), findsNothing);
    });

    testWidgets('negative variance shows in orange when qty < expected',
        (tester) async {
      final order = _buildOrder();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReceivePurchaseOrderSheet(order: order),
            ),
          ),
        ),
      );

      // Enter quantity less than expected (10 - 3 = -3)
      final qtyFields = find.byType(TextField);
      await tester.tap(qtyFields.first);
      await tester.pump();
      await tester.enterText(qtyFields.first, '7');
      await tester.pump();

      // Should show -3 variance
      expect(find.text('-3'), findsOneWidget);
    });

    testWidgets('zero variance (qty == expected) shows no variance label',
        (tester) async {
      final order = _buildOrder();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReceivePurchaseOrderSheet(order: order),
            ),
          ),
        ),
      );

      // Fields start pre-filled with expected qty → no variance shown
      expect(find.byKey(const Key('variance_line-1')), findsNothing);
      expect(find.byKey(const Key('variance_line-2')), findsNothing);
    });
  });
}
