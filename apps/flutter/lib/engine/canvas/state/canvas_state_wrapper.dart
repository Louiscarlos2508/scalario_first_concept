import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

enum CanvasState { loading, empty, error, success }

class CanvasStateWrapper extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasStateWrapper({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasStateWrapper(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final states = config.props['states'] as Map<String, dynamic>? ?? {};
    final sourceData = config.props['_source_data'] as Map?;

    CanvasState currentState;
    if (config.props['_loading'] == true) {
      currentState = CanvasState.loading;
    } else if (config.props['_error'] != null) {
      currentState = CanvasState.error;
    } else if (sourceData == null || (sourceData is List && sourceData.isEmpty)) {
      currentState = CanvasState.empty;
    } else {
      currentState = CanvasState.success;
    }

    return switch (currentState) {
      CanvasState.loading => _buildLoading(states),
      CanvasState.empty => _buildEmpty(states),
      CanvasState.error => _buildError(states, config.props['_error']),
      CanvasState.success => _buildContent(),
    };
  }

  Widget _buildLoading(Map states) {
    if (states['loading'] != null) {
      final cfg = ComponentConfig.fromJson({'type': 'Skeleton', 'props': {}});
      return ScalarioCanvasRegistry.instance?.build(cfg, ctx) ?? const SizedBox.shrink();
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmpty(Map states) {
    final emptyCfg = states['empty'] as Map<String, dynamic>?;
    if (emptyCfg != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_icon(emptyCfg['illustration'] as String? ?? 'inbox'), size: 48),
        const SizedBox(height: 8),
        Text(emptyCfg['message_key'] as String? ?? 'Aucune donnee'),
        if (emptyCfg['action'] != null)
          TextButton(onPressed: () {}, child: Text(emptyCfg['action'] as String? ?? 'Creer')),
      ]));
    }
    return const Center(child: Text('Aucune donnee'));
  }

  Widget _buildError(Map states, dynamic error) {
    final errorCfg = states['error'] as Map<String, dynamic>?;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      Text(error?.toString() ?? 'Erreur'),
      if (errorCfg?['retry'] == true) TextButton(onPressed: () {}, child: const Text('Reessayer')),
    ]));
  }

  Widget _buildContent() {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return const SizedBox.shrink();
    final children = config.children ?? [];
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children.map((c) => r.build(c, ctx)).toList());
  }

  IconData _icon(String name) {
    switch (name) {
      case 'empty_box': return Icons.inbox_outlined;
      case 'empty_cart': return Icons.shopping_cart_outlined;
      default: return Icons.inbox_outlined;
    }
  }
}
