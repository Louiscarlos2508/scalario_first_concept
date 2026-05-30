import 'package:flutter/material.dart';

import '../../canvas_registry/component_config.dart';
import '../../../core/design_system/tokens/tokens.dart';

class CanvasMedia extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;

  const CanvasMedia({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasMedia(config: config, ctx: ctx);
  }

  @override
  Widget build(BuildContext context) {
    final type = config.props['type'] as String? ?? 'icon';
    final iconName = config.props['icon'] as String?;
    final label = config.props['label'] as String?;
    final size = config.props['size'] as num? ?? 24;
    final colorName = config.props['color'] as String?;
    final color = _colorFor(colorName);

    switch (type) {
      case 'avatar':
        return _buildAvatar(iconName, label, size);
      case 'image':
        return _buildImage(iconName, size, context);
      default:
        return Icon(_iconFor(iconName ?? 'dashboard'), size: size.toDouble(), color: color);
    }
  }

  Widget _buildAvatar(String? iconName, String? label, num size) {
    if (label != null && label.isNotEmpty) {
      return CircleAvatar(
        radius: size.toDouble() / 2,
        child: Text(label[0].toUpperCase(), style: TextStyle(fontSize: size.toDouble() * 0.5)),
      );
    }
    return CircleAvatar(
      radius: size.toDouble() / 2,
      child: Icon(_iconFor(iconName ?? 'person'), size: size.toDouble() * 0.6),
    );
  }

  Widget _buildImage(String? url, num size, BuildContext context) {
    if (url != null && url.startsWith('http')) {
      return Image.network(url, width: size.toDouble(), height: size.toDouble(), fit: BoxFit.cover);
    }
    return Icon(_iconFor(url ?? 'image'), size: size.toDouble(), color: Theme.of(context).colorScheme.onSurfaceVariant);
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'person': return Icons.person;
      case 'image': return Icons.image;
      case 'store': return Icons.store;
      case 'dashboard': return Icons.dashboard;
      default: return Icons.dashboard;
    }
  }

  Color? _colorFor(String? name) {
    if (name == null) return null;
    switch (name) {
      case 'primary': return ScalarioColors.primary500;
      case 'success': return ScalarioColors.success500;
      case 'warning': return ScalarioColors.warning500;
      case 'danger': return ScalarioColors.danger500;
      case 'info': return ScalarioColors.info500;
      case 'disabled': return Theme.of(ctx).colorScheme.onSurfaceVariant;
      default: return null;
    }
  }
}
