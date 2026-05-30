import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';

import 'engine/a2ui/a2ui_canvas.dart';
import 'engine/canvas_registry/scalario_canvas_registry.dart';
import 'main.dart' show themeModeNotifier;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>>? _messages;
  String? _error;

  @override
  void initState() {
    super.initState();
    themeModeNotifier.addListener(_onThemeChanged);
    _loadDashboard();
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _cycleTheme() {
    final current = themeModeNotifier.value;
    final next = <ThemeMode>[ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final idx = (next.indexOf(current) + 1) % next.length;
    themeModeNotifier.value = next[idx];
  }

  IconData _themeIcon() {
    switch (themeModeNotifier.value) {
      case ThemeMode.light: return Icons.light_mode;
      case ThemeMode.dark: return Icons.dark_mode;
      case ThemeMode.system: return Icons.brightness_auto;
    }
  }

  String _themeLabel() {
    switch (themeModeNotifier.value) {
      case ThemeMode.light: return 'Clair';
      case ThemeMode.dark: return 'Sombre';
      case ThemeMode.system: return 'Auto';
    }
  }

  Future<void> _loadDashboard() async {
    try {
      final raw = await rootBundle.loadString('assets/sandbox/a2ui_dashboard.json');
      final decoded = jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _messages = decoded.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        child: Column(
          children: [
            _buildThemeBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_themeIcon(), size: 20),
            onPressed: _cycleTheme,
            tooltip: 'Changer le thème',
          ),
          Text(_themeLabel(), style: Theme.of(context).textTheme.labelMedium),
          const Spacer(),
          Text('Scalario', style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Erreur', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      );
    }

    if (_messages == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final registry = GetIt.I<ScalarioCanvasRegistry>();

    return ExcludeSemantics(
      child: A2UICanvas(
        registry: registry,
        initialMessages: _messages!,
      ),
    );
  }
}
