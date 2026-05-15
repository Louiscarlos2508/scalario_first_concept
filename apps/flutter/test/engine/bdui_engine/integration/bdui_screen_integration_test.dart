// Integration tests for BDUIScreen rendering the 3 sandbox fixtures
// programmatically (no rootBundle). Verifies AC-17 → AC-20.
//
// Loads the JSON files directly from disk to keep them in sync with
// `assets/sandbox/*.json` — the same content shipped to the app.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/components/data_display/kpi_card.dart';
import 'package:scalario/components/feedback/alert_banner.dart';
import 'package:scalario/components/inputs/form_section.dart';
import 'package:scalario/components/lists/scalario_list_tile.dart';
import 'package:scalario/engine/bdui_engine/bdui_engine.dart';
import 'package:scalario/engine/bdui_engine/bdui_screen.dart';
import 'package:scalario/engine/bdui_engine/data_source_resolver.dart';
import 'package:scalario/engine/bdui_engine/json_schema_validator.dart';
import 'package:scalario/engine/bdui_engine/user_context_provider.dart';
import 'package:scalario/core/theme/scalario_theme.dart';
import 'package:scalario/engine/component_registry/component_registry.dart';
import 'package:scalario/engine/component_registry/registry_bootstrap.dart';
import 'package:scalario/engine/layout_resolver/layout_resolver.dart';
import 'package:scalario/engine/rule_evaluator/rule_evaluator.dart';

class _Provider implements UserContextProvider {
  _Provider(this.role);
  String role;
  @override
  UserContext get current => UserContext(
        userId: 'u',
        tenantId: 't',
        roles: <String>{role},
      );
}

Map<String, dynamic> _loadFixture(String name) {
  final File f = File('assets/sandbox/$name.json');
  if (!f.existsSync()) {
    throw StateError('Fixture not found: ${f.absolute.path}');
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

BDUIEngine _engineFor(Map<String, Map<String, dynamic>> screens, _Provider p) {
  final ComponentRegistry registry = ComponentRegistry();
  RegistryBootstrap.registerPhase1(registry);
  return BDUIEngine(
    registry: registry,
    evaluator: const RuleEvaluator(),
    layoutResolver: LayoutResolver(registry: registry),
    dataResolver: InMemoryDataSourceResolver(screens: screens),
    userContextProvider: p,
    validator: const StructuralScreenValidator(),
  );
}

Future<void> _pumpScreen(WidgetTester tester, BDUIEngine engine, String id) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ScalarioTheme.light(),
      home: BDUIScreen(screenId: id, engine: engine),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('retail_dashboard.json renders KPIs + alert + FAB',
      (WidgetTester tester) async {
    final Map<String, dynamic> json = _loadFixture('retail_dashboard');
    final _Provider provider = _Provider('OWNER');
    final BDUIEngine engine = _engineFor(
      <String, Map<String, dynamic>>{'retail_dashboard': json},
      provider,
    );
    await _pumpScreen(tester, engine, 'retail_dashboard');

    expect(find.text('Ventes du jour'), findsOneWidget);
    expect(find.text('Panier moyen'), findsOneWidget);
    expect(find.text('Marge brute'), findsOneWidget); // OWNER → visible
    expect(find.byType(KPICard), findsWidgets);
    expect(find.byType(AlertBanner), findsOneWidget);
  });

  testWidgets(
      'retail_dashboard.json hides OWNER-gated KPI for CASHIER (AC-20)',
      (WidgetTester tester) async {
    final Map<String, dynamic> json = _loadFixture('retail_dashboard');
    final _Provider provider = _Provider('CASHIER');
    final BDUIEngine engine = _engineFor(
      <String, Map<String, dynamic>>{'retail_dashboard': json},
      provider,
    );
    await _pumpScreen(tester, engine, 'retail_dashboard');

    expect(find.text('Ventes du jour'), findsOneWidget); // public
    expect(find.text('Marge brute'), findsNothing); // OWNER-only
  });

  testWidgets('simple_form.json renders FormSection',
      (WidgetTester tester) async {
    final Map<String, dynamic> json = _loadFixture('simple_form');
    final BDUIEngine engine = _engineFor(
      <String, Map<String, dynamic>>{'simple_form': json},
      _Provider('OWNER'),
    );
    await _pumpScreen(tester, engine, 'simple_form');

    expect(find.byType(FormSection), findsOneWidget);
  });

  testWidgets('transactions_list.json renders list items',
      (WidgetTester tester) async {
    final Map<String, dynamic> json = _loadFixture('transactions_list');
    final BDUIEngine engine = _engineFor(
      <String, Map<String, dynamic>>{'transactions_list': json},
      _Provider('OWNER'),
    );
    await _pumpScreen(tester, engine, 'transactions_list');

    expect(find.byType(ScalarioListTile), findsAtLeastNWidgets(4));
    expect(find.textContaining('Vente #1042'), findsOneWidget);
    expect(find.textContaining('Annulation #1039'), findsOneWidget); // OWNER
  });

  testWidgets('transactions_list hides OWNER-only row for CASHIER',
      (WidgetTester tester) async {
    final Map<String, dynamic> json = _loadFixture('transactions_list');
    final BDUIEngine engine = _engineFor(
      <String, Map<String, dynamic>>{'transactions_list': json},
      _Provider('CASHIER'),
    );
    await _pumpScreen(tester, engine, 'transactions_list');

    expect(find.textContaining('Annulation #1039'), findsNothing);
    expect(find.textContaining('Vente #1042'), findsOneWidget);
  });
}
