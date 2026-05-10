import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/actions/scalario_fab.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _FABShowcase extends StatelessWidget {
  const _FABShowcase();
  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          ScalarioFAB(icon: Icons.add, onPressed: () {}, heroTag: 'fab-1'),
          const ScalarioFAB(icon: Icons.add, loading: true, heroTag: 'fab-2'),
        ],
      );
}

void main() {
  testWidgets('FAB showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'FAB Showcase',
      child: _FABShowcase(),
    ));
    expect(find.byType(FloatingActionButton), findsWidgets);
  });
}
