import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasOffline extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasOffline({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasOffline(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final showStale = config.props['show_stale_badge'] as bool? ?? false;
    final disabledActions = (config.props['disable_actions'] as List?)?.cast<String>() ?? [];
    final child = config.children?.isNotEmpty == true && ScalarioCanvasRegistry.instance != null
      ? ScalarioCanvasRegistry.instance!.build(config.children!.first, ctx)
      : const SizedBox.shrink();

    if (!showStale) return child;

    return Column(children: [
      Container(padding: const EdgeInsets.all(4), color: Colors.orange.shade100, child: const Text('Donnees hors ligne', style: TextStyle(fontSize: 10))),
      Expanded(child: child),
    ]);
  }
}

class CanvasKeyboard extends StatelessWidget {
  final ComponentConfig config;
  final Widget child;
  const CanvasKeyboard({super.key, required this.config, required this.child});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasKeyboard(config: config, child: const SizedBox.shrink());
  }

  static Widget wrap(ComponentConfig config, Widget child) {
    final keyboard = config.props['keyboard'] as Map<String, dynamic>?;
    if (keyboard == null) return child;
    final submitOnEnter = keyboard['submit_on_enter'] as bool? ?? false;
    if (submitOnEnter) {
      return Shortcuts(shortcuts: const {}, child: Actions(actions: {}, child: child));
    }
    return child;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class CanvasPrint extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasPrint({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasPrint(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final pageSize = config.props['page_size'] as String? ?? 'A4';
    return Container(
      constraints: BoxConstraints(maxWidth: pageSize == 'A4' ? 595 : 800),
      padding: const EdgeInsets.all(48),
      child: Column(children: [
        Text('Impression — $pageSize', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 16),
      ]),
    );
  }
}
