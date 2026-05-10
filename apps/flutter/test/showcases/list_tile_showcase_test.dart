import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/lists/scalario_list_tile.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _ListTileShowcase extends StatelessWidget {
  const _ListTileShowcase();
  @override
  Widget build(BuildContext context) => const Column(
        children: <Widget>[
          ScalarioListTile(title: 'Vente — Tomates', subtitle: '12 kg'),
          ScalarioListTile(
            title: 'Stock critique',
            status: ListTileStatus.danger,
          ),
          ScalarioListTile.loading(),
        ],
      );
}

void main() {
  testWidgets('ListTile showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'ListTile Showcase',
      child: _ListTileShowcase(),
    ));
    expect(find.text('Vente — Tomates'), findsOneWidget);
  });
}
