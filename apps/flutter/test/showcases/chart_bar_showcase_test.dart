import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/chart_bar.dart';
import 'package:scalario/showcases/_showcase_app.dart';

const List<ChartDataPoint> _data = <ChartDataPoint>[
  ChartDataPoint(label: 'L', value: 38500),
  ChartDataPoint(label: 'M', value: 52000),
];

class _ChartBarShowcase extends StatelessWidget {
  const _ChartBarShowcase();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const ChartBar(title: 'CA', data: _data, height: 120),
            ChartBar.loading(title: 'CA', height: 120),
          ],
        ),
      );
}

void main() {
  testWidgets('ChartBar showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'ChartBar Showcase',
      child: _ChartBarShowcase(),
    ));
    expect(find.text('CA'), findsWidgets);
  });
}
