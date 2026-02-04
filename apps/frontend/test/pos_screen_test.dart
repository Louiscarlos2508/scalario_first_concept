import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/pos/data/models/product.dart';
import 'package:frontend/features/pos/presentation/providers/pos_providers.dart';
import 'package:frontend/features/pos/presentation/screens/pos_screen.dart';

// Mock Data
final mockProducts = [
  Product()
    ..id = 1
    ..name = 'Test Cola'
    ..price = 100
    ..stockQuantity = 10
    ..remoteId = 'test-1',
  Product()
    ..id = 2
    ..name = 'Test Burger'
    ..price = 200
    ..stockQuantity = 5
    ..remoteId = 'test-2',
];

void main() {
  testWidgets('POS Screen renders products and adds to cart', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the product list provider to return mock data
          productListProvider.overrideWith((ref) => Future.value(mockProducts)),
        ],
        child: const MaterialApp(
          home: PosScreen(),
        ),
      ),
    );

    // Initial load might be async
    await tester.pump(); 
    await tester.pump(const Duration(milliseconds: 100)); // Wait for future

    // Verify Product Grid
    expect(find.text('Test Cola'), findsOneWidget);
    expect(find.text('\$100.00'), findsOneWidget);
    expect(find.text('Test Burger'), findsOneWidget);

    // Verify Cart is empty initially
    expect(find.text('Total:'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);

    // Tap to add "Test Cola" - Specific to Grid Card to avoid ambiguity with Cart List
    await tester.tap(find.widgetWithText(Card, 'Test Cola'));
    await tester.pumpAndSettle();

    // Verify Cart Update
    // The grid also shows $100.00. The cart item subtitle shows "1 x $100.00" (updated).
    
    // Check for Cart Item in list
    expect(find.widgetWithText(ListTile, 'Test Cola'), findsOneWidget);
    
    // Tap to add another "Test Cola"
    await tester.tap(find.widgetWithText(Card, 'Test Cola'));
    await tester.pumpAndSettle();

    // Verify Quantity update
    // Subtitle should be "2 x $100.0"
    expect(find.textContaining('2 x'), findsOneWidget);
    
    // Verify Total is $200
    // "Test Burger" in grid ($200.00).
    // Cola Item Trailing ($200.00).
    // Cart Grand Total ($200.00).
    expect(find.text('\$200.00'), findsNWidgets(3));
  });
}
