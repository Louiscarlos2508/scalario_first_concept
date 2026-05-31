import 'dart:convert' show jsonDecode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';

import 'engine/a2ui/a2ui_canvas.dart';
import 'engine/canvas_registry/scalario_canvas_registry.dart';

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
    _loadDashboard();
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
    if (_error != null) {
      return Material(
        child: Center(
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
        ),
      );
    }

    if (_messages == null) {
      return const Material(child: Center(child: CircularProgressIndicator()));
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