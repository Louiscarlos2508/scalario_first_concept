import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/scalario_data_table.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _Row {
  const _Row(this.name);
  final String name;
}

class _DataTableShowcase extends StatelessWidget {
  const _DataTableShowcase();
  @override
  Widget build(BuildContext context) => ScalarioDataTable<_Row>(
        columns: <DataColumnConfig<_Row>>[
          DataColumnConfig<_Row>(
            key: 'name',
            label: 'Nom',
            cellBuilder: (_Row r) => r.name,
          ),
        ],
        rows: const <_Row>[_Row('Tenant Démo'), _Row('Acme SARL')],
      );
}

void main() {
  testWidgets('DataTable showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'DataTable Showcase',
      child: _DataTableShowcase(),
    ));
    expect(find.text('Tenant Démo'), findsOneWidget);
  });
}
