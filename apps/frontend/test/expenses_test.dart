import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/retail/expenses/data/models/expense.dart';
import 'package:frontend/features/retail/expenses/data/repositories/expense_repository.dart';
import 'package:frontend/features/retail/expenses/presentation/providers/expense_providers.dart';
import 'package:frontend/features/retail/expenses/presentation/screens/expenses_screen.dart';
import 'package:frontend/features/retail/expenses/presentation/widgets/expense_form.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

final _mockExpense = Expense(
  id: 'exp-001',
  tenantId: 'tenant-1',
  userId: 'user-1',
  label: 'Loyer mars',
  amount: 150000,
  category: 'LOYER',
  date: DateTime(2026, 3, 1),
);

Widget _buildScreen({
  required List<Expense> expenses,
  http.Client? httpClient,
}) {
  final repo = ExpenseRepository(httpClient: httpClient ?? MockClient((_) async => http.Response('[]', 200)));

  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      expenseRepositoryProvider.overrideWithValue(repo),
      expensesProvider.overrideWith((ref) => Future.value(expenses)),
    ],
    child: const MaterialApp(home: ExpensesScreen()),
  );
}

Widget _buildForm({http.Client? httpClient}) {
  final repo = ExpenseRepository(
    httpClient: httpClient ?? MockClient((_) async => http.Response('{}', 201)),
  );

  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      expenseRepositoryProvider.overrideWithValue(repo),
      expensesProvider.overrideWith((ref) => Future.value([])),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: ExpenseForm())),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── ExpensesScreen ────────────────────────────────────────────────────────

  group('ExpensesScreen', () {
    testWidgets('shows empty state when no expenses', (tester) async {
      await tester.pumpWidget(_buildScreen(expenses: []));
      await tester.pump();

      expect(find.byKey(const Key('expenses_empty_state')), findsOneWidget);
      expect(find.text('Aucune dépense enregistrée'), findsOneWidget);
    });

    testWidgets('renders expense list tile when expenses present', (tester) async {
      await tester.pumpWidget(_buildScreen(expenses: [_mockExpense]));
      await tester.pump();

      expect(find.text('Loyer mars'), findsOneWidget);
      expect(find.byKey(const Key('expense_tile_exp-001')), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await tester.pumpWidget(_buildScreen(expenses: []));
      await tester.pump();

      expect(find.byKey(const Key('expense_fab')), findsOneWidget);
    });
  });

  // ── ExpenseForm ───────────────────────────────────────────────────────────

  group('ExpenseForm — widget tests', () {
    testWidgets('all fields are present', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      expect(find.byKey(const Key('expense_label_field')), findsOneWidget);
      expect(find.byKey(const Key('expense_amount_field')), findsOneWidget);
      expect(find.byKey(const Key('expense_category_field')), findsOneWidget);
      expect(find.byKey(const Key('expense_date_field')), findsOneWidget);
      expect(find.byKey(const Key('expense_notes_field')), findsOneWidget);
      expect(find.byKey(const Key('expense_submit_button')), findsOneWidget);
    });

    testWidgets('label field is required — shows error when empty', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      // Tap submit without filling label
      await tester.tap(find.byKey(const Key('expense_submit_button')));
      await tester.pump();

      expect(find.text('Label obligatoire'), findsOneWidget);
    });

    testWidgets('amount field is required — shows error when empty', (tester) async {
      await tester.pumpWidget(_buildForm());
      await tester.pump();

      await tester.enterText(find.byKey(const Key('expense_label_field')), 'Test');
      await tester.tap(find.byKey(const Key('expense_submit_button')));
      await tester.pump();

      expect(find.text('Montant obligatoire'), findsOneWidget);
    });

    testWidgets('valid submit calls POST and shows success snackbar', (tester) async {
      final capturedRequests = <http.Request>[];

      final fakeClient = MockClient((request) async {
        capturedRequests.add(request);
        final body = {
          'id': 'exp-new',
          'tenantId': 'tenant-1',
          'userId': 'system',
          'label': 'Loyer',
          'amount': '150000',
          'category': 'LOYER',
          'date': '2026-03-01',
        };
        return http.Response(jsonEncode(body), 201);
      });

      await tester.pumpWidget(_buildForm(httpClient: fakeClient));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('expense_label_field')), 'Loyer');
      await tester.enterText(find.byKey(const Key('expense_amount_field')), '150000');

      await tester.tap(find.byKey(const Key('expense_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(capturedRequests, hasLength(1));
      final reqBody = jsonDecode(capturedRequests.first.body) as Map;
      expect(reqBody['label'], equals('Loyer'));
      expect(reqBody['amount'], equals(150000.0));
      expect(reqBody['tenantId'], equals('tenant-1'));
    });

    testWidgets('shows error snackbar on network failure', (tester) async {
      final fakeClient = MockClient(
        (_) async => http.Response('{"message":"Server error"}', 500),
      );

      await tester.pumpWidget(_buildForm(httpClient: fakeClient));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('expense_label_field')), 'Loyer');
      await tester.enterText(find.byKey(const Key('expense_amount_field')), '150000');

      await tester.tap(find.byKey(const Key('expense_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('snackbar_expense_error')), findsOneWidget);
    });
  });

  // ── ExpenseRepository unit tests ──────────────────────────────────────────

  group('ExpenseRepository', () {
    test('create() returns Expense on 201', () async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode({
              'id': 'exp-1',
              'tenantId': 'tenant-1',
              'userId': 'user-1',
              'label': 'Loyer',
              'amount': '150000',
              'category': 'LOYER',
              'date': '2026-03-01T00:00:00.000Z',
            }),
            201,
          ));

      final repo = ExpenseRepository(httpClient: fakeClient);
      final result = await repo.create(
        tenantId: 'tenant-1',
        label: 'Loyer',
        amount: 150000,
        category: 'LOYER',
        date: DateTime(2026, 3, 1),
      );

      expect(result.id, equals('exp-1'));
      expect(result.label, equals('Loyer'));
      expect(result.amount, equals(150000.0));
    });

    test('list() returns List<Expense> on 200', () async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode([
              {
                'id': 'exp-1',
                'tenantId': 'tenant-1',
                'userId': 'user-1',
                'label': 'Loyer',
                'amount': '150000',
                'category': 'LOYER',
                'date': '2026-03-01T00:00:00.000Z',
              },
            ]),
            200,
          ));

      final repo = ExpenseRepository(httpClient: fakeClient);
      final result = await repo.list(tenantId: 'tenant-1');

      expect(result, hasLength(1));
      expect(result.first.label, equals('Loyer'));
    });

    test('delete() succeeds on 200', () async {
      final fakeClient = MockClient((_) async => http.Response('{}', 200));
      final repo = ExpenseRepository(httpClient: fakeClient);

      // Should not throw
      await expectLater(
        repo.delete('exp-1', tenantId: 'tenant-1'),
        completes,
      );
    });

    test('create() throws on non-2xx response', () async {
      final fakeClient = MockClient(
        (_) async => http.Response('{"message":"Bad Request"}', 400),
      );
      final repo = ExpenseRepository(httpClient: fakeClient);

      await expectLater(
        () => repo.create(
          tenantId: 'tenant-1',
          label: 'Test',
          amount: 1000,
          category: 'AUTRE',
          date: DateTime.now(),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
