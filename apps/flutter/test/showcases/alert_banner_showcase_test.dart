import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/feedback/alert_banner.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _AlertBannerShowcase extends StatelessWidget {
  const _AlertBannerShowcase();
  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
        child: Column(
          children: <Widget>[
            AlertBanner(type: AlertType.critical, message: 'Alerte critique'),
            AlertBanner(type: AlertType.info, message: 'Info'),
          ],
        ),
      );
}

void main() {
  testWidgets('AlertBanner showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'AlertBanner Showcase',
      child: _AlertBannerShowcase(),
    ));
    expect(find.text('Alerte critique'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
  });
}
