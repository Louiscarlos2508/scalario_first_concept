import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

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
    final sidebar = _buildChild(r, config.props['sidebar'], context);
    final drawer = _buildChild(r, config.props['drawer'], context);

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    Widget bodyWidget = body;
    if (sidebar != null && isDesktop) {
      bodyWidget = Row(
        children: [
          SizedBox(width: 240, child: sidebar),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: appBar is PreferredSizeWidget ? appBar : null,
      body: bodyWidget,
      bottomNavigationBar: bottomNav,
      drawer: drawer != null && !isDesktop ? Drawer(child: drawer) : null,
    );
  }

  Widget? _buildChild(ScalarioCanvasRegistry r, dynamic childConfig, BuildContext ctx) {
    if (childConfig == null) return null;
    if (childConfig is ComponentConfig) {
      return RepaintBoundary(child: r.build(childConfig, ctx));
    }
    if (childConfig is Map<String, dynamic>) {
      final cc = ComponentConfig.fromJson(childConfig);
      return RepaintBoundary(child: r.build(cc, ctx));
    }
    return null;
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
          child: RepaintBoundary(child: r.build(c, ctx)),
        )).toList(),
      ),
    );
  }
}