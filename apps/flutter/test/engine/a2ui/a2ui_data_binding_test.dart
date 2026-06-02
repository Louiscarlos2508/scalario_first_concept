import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/a2ui/a2ui_component.dart';
import 'package:scalario/engine/a2ui/a2ui_message.dart';
import 'package:scalario/engine/a2ui/component_translator.dart';
import 'package:scalario/engine/canvas_layout/screen_config.dart';
import 'package:scalario/engine/canvas_registry/component_config.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';

void main() {
  group('A2UIDataModel', () {
    test('resolve returns null for unknown path', () {
      final model = A2UIDataModel();
      expect(model.resolve('/unknown'), isNull);
    });

    test('bulk update via / path loads data', () {
      final model = A2UIDataModel();
      model.update('/', {
        'kpi': {'ca_jour': 145000, 'stock_total': 23450},
        'ventes7j': [
          {'jour': 'Lun', 'montant': 85000},
        ],
      });
      expect(model.resolve('/kpi/ca_jour'), 145000);
      expect(model.resolve('/kpi/stock_total'), 23450);
      final ventes = model.resolve('/ventes7j') as List;
      expect(ventes.length, 1);
      expect((ventes[0] as Map)['jour'], 'Lun');
    });

    test('update with non-Map value at root does nothing', () {
      final model = A2UIDataModel();
      model.update('/', 'not_a_map');
      expect(model.resolve('/anything'), isNull);
    });

    test('nested resolve with deep path', () {
      final model = A2UIDataModel({
        'a': {'b': {'c': 'deep_value'}},
      });
      expect(model.resolve('/a/b/c'), 'deep_value');
      expect(model.resolve('/a'), isA<Map>());
    });
  });

  group('A2UIComponentTranslator', () {
    /// Helper: get the config from whichever zone it landed in.
    ComponentConfig? _firstConfig(ScreenConfig screen) {
      return screen.zones['kpis']?.first ??
          screen.zones['main']?.first ??
          screen.zones['aside']?.first;
    }

    test('translates data binding {path: /kpi/ca_jour} into _a2ui_path marker', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'KPICard',
            'variant': 'default',
            'text': 'CA Jour',
            'value': {'path': '/kpi/ca_jour'},
            'props': {'icon': 'trending_up', 'unit': 'FCFA'},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final config = _firstConfig(screen);
      expect(config, isNotNull);
      expect(config!.props['text'], 'CA Jour');
      expect(config.props['value'], {'_a2ui_path': '/kpi/ca_jour'});
      expect(config.props['icon'], 'trending_up');
      expect(config.props['unit'], 'FCFA');
      expect(config.props.containsKey('props'), isFalse);
    });

    test('KPICard with literal string value stays as-is', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'KPICard',
            'text': 'Test',
            'value': {'literalString': '42'},
            'props': {},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final config = _firstConfig(screen);
      expect(config, isNotNull);
      expect(config!.props['value'], '42');
    });

    test('KPICard without value prop keeps text and icon', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'KPICard',
            'text': 'CA Jour',
            'props': {'icon': 'trending_up'},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final config = _firstConfig(screen);
      expect(config, isNotNull);
      expect(config!.props['text'], 'CA Jour');
      expect(config.props.containsKey('value'), isFalse);
    });

    test('DataTable auto-derives rows path from text', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'DataTable',
            'text': 'Top Produits',
            'props': {},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final config = _firstConfig(screen);
      expect(config, isNotNull);
      expect(config!.props['rows'], {'_a2ui_path': '/top_produits'});
    });

    test('DataTable explicit rows binding prevents auto-derive', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'DataTable',
            'text': 'Top Produits',
            'rows': {'path': '/custom/path'},
            'props': {},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final config = _firstConfig(screen);
      expect(config, isNotNull);
      expect(config!.props['rows'], {'_a2ui_path': '/custom/path'});
    });

    test('ChartBar auto-derives data path from text', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'ChartBar',
            'text': 'Ventes 7 jours',
            'props': {},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final config = _firstConfig(screen);
      expect(config, isNotNull);
      expect(config!.props['data'], {'_a2ui_path': '/ventes_7_jours'});
    });

    test('Row with KPICard children keeps children intact', () {
      final registry = ScalarioCanvasRegistry();
      final translator = A2UIComponentTranslator(registry);

      final msg = UpdateComponents.fromJson({
        'surfaceId': 'test',
        'components': [
          {
            'id': 'root',
            'component': 'Row',
            'children': ['kpi_row'],
            'props': {},
          },
          {
            'id': 'kpi_row',
            'component': 'Row',
            'children': ['ca_jour', 'ca_mois'],
            'props': {'gap': 8},
          },
          {
            'id': 'ca_jour',
            'component': 'KPICard',
            'text': 'CA Jour',
            'value': {'path': '/kpi/ca_jour'},
            'props': {'unit': 'FCFA'},
          },
          {
            'id': 'ca_mois',
            'component': 'KPICard',
            'text': 'CA Mois',
            'value': {'path': '/kpi/ca_mois'},
            'props': {'unit': 'FCFA'},
          },
        ],
      });

      final screen = translator.translate(msg, 'dashboard', null);
      final main = screen.zones['main'];
      expect(main, hasLength(1));

      // Main contains the root's direct children — here kpi_row
      final kpiRow = main![0];
      expect(kpiRow.type, 'Row');
      expect(kpiRow.children, hasLength(2));

      // First KPICard
      final caJour = kpiRow.children![0];
      expect(caJour.type, 'KPICard');
      expect(caJour.props['text'], 'CA Jour');
      expect(caJour.props['value'], {'_a2ui_path': '/kpi/ca_jour'});
      expect(caJour.props['unit'], 'FCFA');
    });
  });

  group('A2UIMessage parsing', () {
    test('updateDataModel with value key', () {
      final msg = A2UIMessage.fromJson({
        'version': 'v0.9',
        'updateDataModel': {
          'surfaceId': 'dashboard',
          'value': {'kpi': {'ca_jour': 145000}},
        },
      });

      expect(msg.type, A2UIMessageType.updateDataModel);
      expect(msg.updateDataModel!.surfaceId, 'dashboard');
      expect(msg.updateDataModel!.path, isNull);
      expect(msg.updateDataModel!.value, isA<Map>());
      expect((msg.updateDataModel!.value as Map)['kpi'], isA<Map>());
    });
  });
}
