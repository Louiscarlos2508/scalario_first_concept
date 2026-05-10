import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/kpi_card.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _KPICardShowcase extends StatelessWidget {
  const _KPICardShowcase();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        child: Column(
          children: <Widget>[
            KPICard(label: 'CA', value: '47 500', unit: 'FCFA'),
            KPICard(label: 'Stock', value: '3', status: KpiStatus.critical),
          ],
        ),
      );
}

void main() {
  testWidgets('KPICard showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'KPICard Showcase',
      child: _KPICardShowcase(),
    ));
    expect(find.text('CA'), findsOneWidget);
    expect(find.text('47 500'), findsOneWidget);
  });
}
