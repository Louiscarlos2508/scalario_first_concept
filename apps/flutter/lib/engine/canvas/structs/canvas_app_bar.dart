import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/colors.dart';
import '../../../core/design_system/tokens/spacing.dart';

class CanvasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasAppBar({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasAppBar(config: config, ctx: ctx);
  }

  @override
  Size get preferredSize {
    final variant = config.variant;
    return Size.fromHeight(variant == 'large' ? 112 : variant == 'brand' ? 56 : variant == 'search' ? 56 : kToolbarHeight);
  }

  @override
  Widget build(BuildContext buildContext) {
    final variant = config.variant;
    final title = config.props['title'] as String? ?? '';

    return switch (variant) {
      'large' => _buildLarge(title, buildContext),
      'brand' => _buildBrand(title, buildContext),
      'transparent' => _buildTransparent(title, buildContext),
      'search' => _buildSearch(title, buildContext),
      'minimal' => _buildMinimal(title, buildContext),
      _ => _buildDefault(title, buildContext),
    };
  }

  AppBar _buildDefault(String title, BuildContext context) {
    return AppBar(title: Text(title), actions: _buildActions());
  }

  AppBar _buildBrand(String title, BuildContext context) {
    return AppBar(
      toolbarHeight: 56,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.point_of_sale, size: 24, color: ScalarioColors.primary500),
          const SizedBox(width: ScalarioSpacing.space2),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        ],
      ),
      actions: _buildActions(),
    );
  }

  AppBar _buildLarge(String title, BuildContext context) {
    return AppBar(toolbarHeight: 112, title: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        if (config.props['subtitle'] != null) Text(config.props['subtitle'] as String, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)))],
    ), actions: _buildActions());
  }

  AppBar _buildTransparent(String title, BuildContext context) {
    return AppBar(title: Text(title), backgroundColor: Colors.transparent, elevation: 0, actions: _buildActions());
  }

  AppBar _buildSearch(String title, BuildContext context) {
    return AppBar(title: TextField(decoration: InputDecoration(hintText: config.props['hint'] as String? ?? 'Rechercher...', border: InputBorder.none)), actions: _buildActions());
  }

  AppBar _buildMinimal(String title, BuildContext context) {
    return AppBar(title: Text(title));
  }

  List<Widget>? _buildActions() {
    final actions = config.props['actions'] as List? ?? [];
    if (actions.isEmpty) return null;
    return actions.map((a) {
      if (a is! Map) return const SizedBox.shrink();
      final iconName = a['icon'] as String? ?? 'circle';
      final badge = a['badge'] as int?;
      final icon = Icon(_iconData(iconName), size: 20);
      if (badge != null && badge > 0) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Badge(label: Text('$badge', style: const TextStyle(fontSize: 10)), child: IconButton(icon: icon, onPressed: () {})),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(icon: icon, onPressed: () {}),
      );
    }).toList();
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'notifications': return Icons.notifications_outlined;
      case 'light_mode': return Icons.light_mode;
      case 'dark_mode': return Icons.dark_mode;
      case 'brightness_auto': return Icons.brightness_auto;
      case 'account_circle': return Icons.account_circle;
      case 'search': return Icons.search;
      case 'more_vert': return Icons.more_vert;
      case 'close': return Icons.close;
      case 'arrow_back': return Icons.arrow_back;
      default: return Icons.circle;
    }
  }
}
