import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasTabs extends StatefulWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasTabs({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasTabs(config: config, ctx: ctx);
  }

  @override
  State<CanvasTabs> createState() => _CanvasTabsState();
}

class _CanvasTabsState extends State<CanvasTabs> {
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.config.props['current'] as int? ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = (widget.config.props['tabs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final children = widget.config.children ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: List.generate(tabs.length, (i) {
              final t = tabs[i];
              final label = t['label'] as String? ?? 'Tab ${i + 1}';
              final iconName = t['icon'] as String?;
              final isSelected = i == _current;
              return Padding(
                padding: const EdgeInsets.only(right: ScalarioSpacing.space1),
                child: Material(
                  color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(ScalarioRadius.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(ScalarioRadius.sm),
                    onTap: () => setState(() => _current = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ScalarioSpacing.space3,
                        vertical: ScalarioSpacing.space2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (iconName != null) ...[
                            Icon(_iconFor(iconName), size: 16, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
                            const SizedBox(width: ScalarioSpacing.space1),
                          ],
                          Text(
                            label,
                            style: DefaultTextStyle.of(context).style.copyWith(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: ScalarioSpacing.space3),
        if (_current < children.length)
          ScalarioCanvasRegistry.instance?.build(children[_current], context) ?? const SizedBox.shrink(),
      ],
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'dashboard': return Icons.dashboard;
      case 'list': return Icons.list;
      case 'chart': return Icons.bar_chart;
      case 'settings': return Icons.settings;
      case 'history': return Icons.history;
      case 'person': return Icons.person;
      case 'inventory': return Icons.inventory;
      case 'receipt': return Icons.receipt;
      case 'star': return Icons.star;
      case 'search': return Icons.search;
      case 'notifications': return Icons.notifications;
      default: return Icons.circle;
    }
  }
}
