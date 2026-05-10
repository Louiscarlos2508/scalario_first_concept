import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/chart_bar.dart';
import 'package:scalario/components/data_display/kpi_card.dart';
import 'package:scalario/components/feedback/alert_banner.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _DashboardOwnerShowcase extends StatelessWidget {
  const _DashboardOwnerShowcase();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const AlertBanner(type: AlertType.warning, message: 'Stock faible'),
            const KPICard(label: 'CA', value: '47 500', unit: 'FCFA'),
            ChartBar.loading(title: 'CA 7 jours', height: 120),
          ],
        ),
      );
}

void main() {
  testWidgets('Dashboard Owner showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'Dashboard Owner',
      child: _DashboardOwnerShowcase(),
    ));
    expect(find.text('Stock faible'), findsOneWidget);
    expect(find.text('CA'), findsWidgets);
  });
}
