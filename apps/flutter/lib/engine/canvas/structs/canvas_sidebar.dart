import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasSidebar extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasSidebar({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasSidebar(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final r = ScalarioCanvasRegistry.instance;
    if (r == null) return const SizedBox.shrink();

    final items = config.props['items'] as List? ?? [];
    final currentIndex = config.props['currentIndex'] as int? ?? 0;

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++) ...[
            _buildItem(context, items[i] as Map<String, dynamic>, i == currentIndex),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> item, bool isSelected) {
    final label = item['label'] as String? ?? '';
    final iconName = item['icon'] as String?;

    return Material(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withAlpha(60) : Colors.transparent,
      child: InkWell(
        onTap: () {
          final action = item['action'] as Map<String, dynamic>?;
          if (action != null) {
            final r = ScalarioCanvasRegistry.instance;
            r?.build(ComponentConfig.fromJson(action), ctx);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (iconName != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(_iconData(iconName), size: 20, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                ),
              Text(label, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400)),
              if (isSelected) ...[
                const Spacer(),
                Container(width: 3, height: 20, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(2))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 12, color: Colors.green),
          const SizedBox(width: 8),
          Text('Synchronisé', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'home': return Icons.home_outlined;
      case 'inventory_2': return Icons.inventory_2_outlined;
      case 'shopping_cart': return Icons.shopping_cart_outlined;
      case 'bar_chart': return Icons.bar_chart_outlined;
      case 'group': return Icons.group_outlined;
      case 'settings': return Icons.settings_outlined;
      default: return Icons.circle;
    }
  }
}