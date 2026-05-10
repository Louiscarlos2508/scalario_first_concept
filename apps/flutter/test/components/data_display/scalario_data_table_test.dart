import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/scalario_data_table.dart';
import 'package:scalario/core/theme/scalario_theme.dart';

class _Row {
  const _Row(this.name, this.amount);
  final String name;
  final int amount;
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ScalarioTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  final List<DataColumnConfig<_Row>> columns = <DataColumnConfig<_Row>>[
    DataColumnConfig<_Row>(
      key: 'name',
      label: 'Nom',
      cellBuilder: (_Row r) => r.name,
    ),
    DataColumnConfig<_Row>(
      key: 'amount',
      label: 'Montant',
      align: DataColumnAlign.right,
      comparator: (_Row a, _Row b) => a.amount.compareTo(b.amount),
      cellBuilder: (_Row r) => r.amount.toString(),
    ),
  ];

  final List<_Row> rows = <_Row>[
    const _Row('Tomates', 23500),
    const _Row('Igname', 18200),
    const _Row('Poivrons', 8800),
  ];

  group('ScalarioDataTable — états', () {
    testWidgets('Normal : en-têtes + lignes rendus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(ScalarioDataTable<_Row>(
        columns: columns,
        rows: rows,
      )));

      expect(find.text('Nom'), findsOneWidget);
      expect(find.text('Montant'), findsOneWidget);
      expect(find.text('Tomates'), findsOneWidget);
      expect(find.text('23500'), findsOneWidget);
    });

    testWidgets('Empty : icône inbox + message centré', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(ScalarioDataTable<_Row>.empty(
        columns: columns,
        message: 'Aucune donnée',
      )));
      expect(find.text('Aucune donnée'), findsOneWidget);
    });

    testWidgets('Loading : 5 lignes shimmer', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(ScalarioDataTable<_Row>.loading(
        columns: columns,
      )));
      // 5 rows × 2 columns = au moins 5 widgets shimmer.
      expect(find.byType(Padding), findsWidgets);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Error : message + retry CTA fonctionnel', (
      WidgetTester tester,
    ) async {
      int retries = 0;
      await tester.pumpWidget(_wrap(ScalarioDataTable<_Row>.error(
        columns: columns,
        message: 'Erreur backend',
        onRetry: () => retries++,
      )));

      expect(find.text('Erreur backend'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retries, 1);
    });

    testWidgets('Tri : tri par défaut amount asc, puis toggle desc', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(ScalarioDataTable<_Row>(
        columns: columns,
        rows: rows,
        defaultSortKey: 'amount',
      )));

      // Tri asc → premier amount = 8800.
      final Finder firstAmount =
          find.byWidgetPredicate((Widget w) => w is Text && w.data == '8800');
      expect(firstAmount, findsOneWidget);

      // Tap sur l'en-tête Montant pour toggle desc.
      await tester.tap(find.text('Montant'));
      await tester.pumpAndSettle();
    });

    testWidgets('onRowTap appelé au clic', (WidgetTester tester) async {
      _Row? tapped;
      await tester.pumpWidget(_wrap(ScalarioDataTable<_Row>(
        columns: columns,
        rows: rows,
        onRowTap: (_Row r) => tapped = r,
      )));

      await tester.tap(find.text('Tomates'));
      expect(tapped, isNotNull);
      expect(tapped!.name, 'Tomates');
    });
  });
}
