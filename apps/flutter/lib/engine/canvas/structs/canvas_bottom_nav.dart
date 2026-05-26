import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';

class CanvasBottomNav extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasBottomNav({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasBottomNav(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final items = (config.props['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentIndex = config.props['currentIndex'] as int? ?? 0;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (_) {},
      items: items.map((i) => BottomNavigationBarItem(
        icon: Icon(_icon(i['icon'] as String? ?? 'circle')),
        label: i['label'] as String? ?? '',
      )).toList(),
    );
  }

  IconData _icon(String name) {
    switch (name) {
      case 'home': return Icons.home;
      case 'inventory_2': return Icons.inventory_2;
      case 'history': return Icons.history;
      case 'group': return Icons.group;
      case 'settings': return Icons.settings;
      case 'bar_chart': return Icons.bar_chart;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'notifications': return Icons.notifications;
      default: return Icons.circle;
    }
  }
}
