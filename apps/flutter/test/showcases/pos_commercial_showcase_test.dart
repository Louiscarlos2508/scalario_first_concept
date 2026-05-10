import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/actions/scalario_fab.dart';
import 'package:scalario/components/data_display/kpi_card.dart';
import 'package:scalario/components/lists/scalario_list_tile.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _POSCommercialShowcase extends StatelessWidget {
  const _POSCommercialShowcase();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const ScalarioListTile(title: 'Tomates', subtitle: '2 kg · 500/kg'),
            const KPICard(label: 'Total panier', value: '4 200', unit: 'FCFA'),
            ScalarioFAB(
              icon: Icons.payments_outlined,
              label: 'Encaisser',
              onPressed: () {},
              heroTag: 'pos-test',
            ),
          ],
        ),
      );
}

void main() {
  testWidgets('POS Commercial showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'POS Commercial',
      child: _POSCommercialShowcase(),
    ));
    expect(find.text('Tomates'), findsOneWidget);
    expect(find.text('Total panier'), findsOneWidget);
  });
}
