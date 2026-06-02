import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:scalario/engine/canvas_registry/scalario_canvas_registry.dart';
import 'package:scalario/engine/canvas_registry/registry_bootstrap.dart';
import 'package:scalario/sandbox/sandbox_file_watcher.dart';
import 'package:scalario/sandbox/sandbox_json_loader.dart';
import 'package:scalario/sandbox/sandbox_screen.dart';
import 'package:scalario/sandbox/sandbox_user_context.dart';

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.data);
  final Map<String, String> data;

  @override
  Future<ByteData> load(String key) async {
    final String? raw = data[key];
    if (raw == null) {
      throw Exception('asset not found: $key');
    }
    return ByteData.view(Uint8List.fromList(utf8.encode(raw)).buffer);
  }
}

const String _kEmpty = '''
{
  "schema_version": "1.0.0",
  "screen": "empty_screen",
  "layout": "detail",
  "title": "Sandbox vide",
  "zones": {
    "main": [
      {
        "type": "AlertBanner",
        "id": "b1",
        "props": {"type": "info", "message": "Hello sandbox"}
      }
    ]
  }
}
''';

const String _kOwnerOnly = '''
{
  "schema_version": "1.0.0",
  "screen": "empty_screen",
  "layout": "detail",
  "title": "Owner only",
  "zones": {
    "main": [
      {
        "type": "AlertBanner",
        "id": "b1",
        "props": {"type": "info", "message": "VISIBLE_TO_OWNER"},
        "visible_if": {"role": ["OWNER"]}
      }
    ]
  }
}
''';

const String _kBroken = '''
{
  "schema_version": "1.0.0",
  "screen": "broken",
  "layout": "detail",
  bad
}
''';

ScalarioCanvasRegistry _registry() {
  final r = ScalarioCanvasRegistry();
  RegistryBootstrap.registerPhase1(r);
  return r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    if (GetIt.I.isRegistered<ScalarioCanvasRegistry>()) {
      GetIt.I.reset();
    }
  });

  testWidgets('renders a fixture loaded via the loader (AC-04/AC-05)',
      (WidgetTester tester) async {
    final bundle = _FakeBundle({
      'assets/sandbox/empty_screen.json': _kEmpty,
    });
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));
    final registry = _registry();

    await tester.pumpWidget(MaterialApp(
      home: SandboxScreen(
        loader: loader,
        watcher: const NoopFileWatcher(),
        componentRegistry: registry,
        
        initialFixtureId: 'empty_screen',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('BDUI Sandbox (dev)'), findsOneWidget);
    expect(find.text('Hello sandbox'), findsOneWidget);
  });

  testWidgets('UserContext switch hides visible_if components (AC-19)',
      (WidgetTester tester) async {
    final bundle = _FakeBundle({
      'assets/sandbox/empty_screen.json': _kOwnerOnly,
    });
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));
    final registry = _registry();
    final userCtx = SandboxUserContextProvider();

    await tester.pumpWidget(MaterialApp(
      home: SandboxScreen(
        loader: loader,
        watcher: const NoopFileWatcher(),
        userContext: userCtx,
        componentRegistry: registry,
        
        initialFixtureId: 'empty_screen',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('VISIBLE_TO_OWNER'), findsOneWidget);

    userCtx.selectPreset(SandboxUserPreset.cashier);
    await tester.pumpAndSettle();
    expect(find.text('VISIBLE_TO_OWNER'), findsNothing);
  });

  testWidgets('invalid JSON renders SandboxErrorView (AC-11)',
      (WidgetTester tester) async {
    final bundle = _FakeBundle({
      'assets/sandbox/empty_screen.json': _kBroken,
    });
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));
    final registry = _registry();

    await tester.pumpWidget(MaterialApp(
      home: SandboxScreen(
        loader: loader,
        watcher: const NoopFileWatcher(),
        componentRegistry: registry,
        
        initialFixtureId: 'empty_screen',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('JSON invalide'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('reload button re-invokes loader and triggers indicator',
      (WidgetTester tester) async {
    int reads = 0;
    final bundle = _CountingBundle(
      onRead: () => reads++,
      data: {'assets/sandbox/empty_screen.json': _kEmpty},
    );
    final loader = SandboxJsonLoader(source: BundleJsonSource(bundle: bundle));
    final registry = _registry();

    await tester.pumpWidget(MaterialApp(
      home: SandboxScreen(
        loader: loader,
        watcher: const NoopFileWatcher(),
        componentRegistry: registry,
        
        initialFixtureId: 'empty_screen',
      ),
    ));
    await tester.pumpAndSettle();
    final initialReads = reads;

    await tester.tap(find.byTooltip('Reload'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
    expect(reads, greaterThan(initialReads));
  });
}

class _CountingBundle extends CachingAssetBundle {
  _CountingBundle({required this.onRead, required this.data});
  final void Function() onRead;
  final Map<String, String> data;

  @override
  Future<ByteData> load(String key) async {
    onRead();
    final String? raw = data[key];
    if (raw == null) throw Exception('asset not found: $key');
    return ByteData.view(Uint8List.fromList(utf8.encode(raw)).buffer);
  }
}
