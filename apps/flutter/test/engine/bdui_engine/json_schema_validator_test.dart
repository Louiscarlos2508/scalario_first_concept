import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/engine/canvas/json_schema_validator.dart';
import 'package:scalario/engine/error_boundary/bdui_error_boundary.dart';

void main() {
  const StructuralScreenValidator validator = StructuralScreenValidator();

  Map<String, dynamic> validScreen() => <String, dynamic>{
        'screen': 'demo',
        'schema_version': '1.0.0',
        'layout': 'dashboard',
        'zones': <String, dynamic>{
          'kpis': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'KPICard',
              'props': <String, dynamic>{'label': 'L', 'value': 'V'},
            },
          ],
        },
      };

  test('accepts a minimal valid screen', () {
    expect(() => validator.validateScreen(validScreen()), returnsNormally);
  });

  test('rejects missing "screen" field', () {
    final json = validScreen()..remove('screen');
    expect(
      () => validator.validateScreen(json),
      throwsA(
        isA<BDUIValidationException>()
            .having((e) => e.jsonPath, 'jsonPath', 'screen'),
      ),
    );
  });

  test('rejects empty schema_version', () {
    final json = validScreen()..['schema_version'] = '';
    expect(
      () => validator.validateScreen(json),
      throwsA(isA<BDUIValidationException>()),
    );
  });

  test('rejects unknown layout', () {
    final json = validScreen()..['layout'] = 'carousel';
    expect(
      () => validator.validateScreen(json),
      throwsA(
        isA<BDUIValidationException>()
            .having((e) => e.jsonPath, 'jsonPath', 'layout'),
      ),
    );
  });

  test('rejects zone that is not an array', () {
    final json = validScreen();
    (json['zones'] as Map<String, dynamic>)['main'] = 'not-a-list';
    expect(
      () => validator.validateScreen(json),
      throwsA(
        isA<BDUIValidationException>()
            .having((e) => e.jsonPath, 'jsonPath', 'zones.main'),
      ),
    );
  });

  test('rejects component without "type"', () {
    final json = validScreen();
    final Map<String, dynamic> zones = json['zones'] as Map<String, dynamic>;
    (zones['kpis'] as List)[0] = <String, dynamic>{
      'props': <String, dynamic>{'label': 'L'},
    };
    expect(
      () => validator.validateScreen(json),
      throwsA(
        isA<BDUIValidationException>()
            .having((e) => e.jsonPath, 'jsonPath', 'zones.kpis[0].type'),
      ),
    );
  });
}
