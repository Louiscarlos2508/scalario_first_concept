import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scalario/sandbox/sandbox_json_loader.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._data);
  final Map<String, String> _data;

  @override
  Future<ByteData> load(String key) async {
    final String? raw = _data[key];
    if (raw == null) {
      throw Exception('asset not found: $key');
    }
    final Uint8List bytes = Uint8List.fromList(utf8.encode(raw));
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  test('SandboxJsonLoader returns parsed map on valid JSON', () async {
    final bundle = _FakeBundle({
      'assets/sandbox/empty_screen.json':
          '{"schema_version":"1.0.0","screen":"empty_screen","layout":"detail"}',
    });
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));

    final raw = await loader.load('empty_screen');
    expect(raw['screen'], 'empty_screen');
  });

  test('SandboxJsonLoader surfaces line/col on invalid JSON', () async {
    final bundle = _FakeBundle({
      'assets/sandbox/broken.json': '{\n  "screen": "x",\n  ',
    });
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));

    SandboxParseException? caught;
    try {
      await loader.load('broken');
    } on SandboxParseException catch (e) {
      caught = e;
    }
    expect(caught, isNotNull);
    expect(caught!.path, 'assets/sandbox/broken.json');
    expect(caught.line, isNotNull);
    expect(caught.column, isNotNull);
  });

  test('SandboxJsonLoader throws when root is not an object', () async {
    final bundle = _FakeBundle({
      'assets/sandbox/list.json': '[1,2,3]',
    });
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));

    expect(loader.load('list'), throwsA(isA<SandboxParseException>()));
  });

  test('fixture id list has 5 entries (AC-15)', () {
    expect(kSandboxFixtureIds.length, 5);
    expect(kSandboxFixtureIds, contains('empty_screen'));
    expect(kSandboxFixtureIds, contains('error_state'));
  });
}
