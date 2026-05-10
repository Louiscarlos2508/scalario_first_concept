import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/inputs/form_section.dart';
import 'package:scalario/showcases/_showcase_app.dart';

class _FormSectionShowcase extends StatelessWidget {
  const _FormSectionShowcase();
  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          FormSection(
            title: 'DÉTAILS',
            children: const <Widget>[
              TextField(decoration: InputDecoration(labelText: 'Produit')),
            ],
          ),
          FormSection(
            title: 'ERREURS',
            errors: const <FormFieldError>[
              FormFieldError(fieldKey: 'f', message: 'Champ requis'),
            ],
            children: const <Widget>[
              TextField(decoration: InputDecoration(labelText: 'Quantité')),
            ],
          ),
        ],
      );
}

void main() {
  testWidgets('FormSection showcase se monte sans exception', (WidgetTester tester) async {
    await tester.pumpWidget(const ScalarioShowcaseApp(
      title: 'FormSection Showcase',
      child: SingleChildScrollView(child: _FormSectionShowcase()),
    ));
    expect(find.text('DÉTAILS'), findsOneWidget);
  });
}
