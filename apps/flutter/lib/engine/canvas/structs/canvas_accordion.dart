import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/spacing.dart';
import '../../../core/design_system/tokens/icons.dart';

class CanvasAccordion extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasAccordion({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasAccordion(config: config, ctx: ctx);
  }

  @override
  State<CanvasAccordion> createState() => _CanvasAccordionState();
}

class _CanvasAccordionState extends State<CanvasAccordion> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.config.props['expanded'] as bool? ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.config.props['title'] as String? ?? widget.config.props['text'] as String? ?? '';
    final iconName = widget.config.props['icon'] as String?;
    final children = widget.config.children ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(ScalarioRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(ScalarioSpacing.space4),
              child: Row(
                children: [
                  if (iconName != null) ...[
                    Icon(_iconFor(iconName), size: ScalarioIconSize.sm, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: ScalarioSpacing.space2),
                  ],
                  Expanded(child: Text(title, style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w600))),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: ScalarioIconSize.sm),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                ScalarioSpacing.space4,
                0,
                ScalarioSpacing.space4,
                ScalarioSpacing.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: children.map((c) {
                  final r = ScalarioCanvasRegistry.instance;
                  if (r == null) return const SizedBox.shrink();
                  final child = Padding(
                    padding: const EdgeInsets.only(bottom: ScalarioSpacing.space2),
                    child: r.build(c, context),
                  );
                  return child;
                }).toList(),
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'filter_list': return Icons.filter_list;
      case 'settings': return Icons.settings;
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      case 'expand': return Icons.expand_more;
      default: return Icons.expand_more;
    }
  }
}
