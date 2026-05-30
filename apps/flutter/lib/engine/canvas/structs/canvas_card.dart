import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasCard extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasCard({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasCard(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final hasHeader = config.props['header'] != null;
    final hasFooter = config.props['footer'] != null;
    final hasBody = config.props['body'] != null;

    final r = ScalarioCanvasRegistry.instance;

    if (!hasHeader && !hasBody && !hasFooter) {
      return _buildFlatChildren(context, r);
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader)
            Container(
              padding: const EdgeInsets.fromLTRB(
                ScalarioSpacing.space4,
                ScalarioSpacing.space4,
                ScalarioSpacing.space4,
                ScalarioSpacing.space2,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: _buildSlot(context, r, config.props['header']),
            ),
          if (hasBody)
            Padding(
              padding: EdgeInsets.fromLTRB(
                ScalarioSpacing.space4,
                hasHeader ? 0 : ScalarioSpacing.space4,
                ScalarioSpacing.space4,
                hasFooter ? ScalarioSpacing.space2 : ScalarioSpacing.space4,
              ),
              child: _buildSlot(context, r, config.props['body']),
            ),
          if (hasFooter)
            Container(
              padding: const EdgeInsets.fromLTRB(
                ScalarioSpacing.space4,
                ScalarioSpacing.space2,
                ScalarioSpacing.space4,
                ScalarioSpacing.space4,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: _buildSlot(context, r, config.props['footer']),
            ),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, ScalarioCanvasRegistry? r, dynamic slotConfig) {
    if (slotConfig == null || r == null) return const SizedBox.shrink();
    if (slotConfig is ComponentConfig) {
      return r.build(slotConfig, context);
    }
    if (slotConfig is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: slotConfig.map((child) {
          if (child is ComponentConfig) {
            return r.build(child, context);
          }
          if (child is Map<String, dynamic>) {
            final cc = ComponentConfig.fromJson(child);
            return r.build(cc, context);
          }
          return const SizedBox.shrink();
        }).toList(),
      );
    }
    if (slotConfig is Map<String, dynamic>) {
      final cc = ComponentConfig.fromJson(slotConfig);
      return r.build(cc, context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildFlatChildren(BuildContext context, ScalarioCanvasRegistry? r) {
    final children = config.children ?? [];
    final widgets = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(
          ScalarioSpacing.space4,
          i == 0 ? ScalarioSpacing.space4 : ScalarioSpacing.space2,
          ScalarioSpacing.space4,
          i == children.length - 1 ? ScalarioSpacing.space4 : 0,
        ),
        child: r?.build(children[i], context) ?? const SizedBox.shrink(),
      ));
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }
}
