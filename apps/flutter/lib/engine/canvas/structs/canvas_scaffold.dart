import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../error_boundary/error_boundary.dart';

class CanvasScaffold extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasScaffold({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasScaffold(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return const SizedBox.shrink();

    final appBar = _buildChild(r, config.props['appBar'], context);
    final body = _buildChild(r, config.props['body'], context) ?? _childrenColumn(r, context);
    final bottomNav = _buildChild(r, config.props['bottomNav'], context);

    return Scaffold(
      appBar: _unwrapPreferredSize(appBar) ?? _unwrapPreferredSize(_childrenColumn(r, context)),
      body: body ?? _childrenColumn(r, context),
      bottomNavigationBar: bottomNav,
    );
  }

  PreferredSizeWidget? _unwrapPreferredSize(Widget? widget) {
    if (widget is PreferredSizeWidget) return widget;
    if (widget is ErrorBoundary && widget.child is PreferredSizeWidget) {
      return widget.child as PreferredSizeWidget;
    }
    return null;
  }

  Widget? _buildChild(ScalarioCanvasRegistry r, dynamic childConfig, BuildContext ctx) {
    if (childConfig == null || childConfig is! Map) return null;
    final cc = ComponentConfig.fromJson(childConfig as Map<String, dynamic>);
    return r.build(cc, ctx);
  }

  Widget _childrenColumn(ScalarioCanvasRegistry r, BuildContext ctx) {
    final children = config.children ?? [];
    if (children.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: r.build(c, ctx),
        )).toList(),
      ),
    );
  }
}
