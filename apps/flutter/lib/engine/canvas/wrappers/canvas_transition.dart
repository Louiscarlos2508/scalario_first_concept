import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';

class CanvasTransition extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasTransition({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasTransition(config: config, ctx: ctx);
  }

  static Route<T> createRoute<T>(WidgetBuilder builder, ComponentConfig config) {
    final transition = config.props['transition'] as String? ?? 'slide';
    final heroTag = config.props['hero_tag'] as String?;

    switch (transition) {
      case 'fade':
        return PageRouteBuilder<T>(pageBuilder: (_, __, ___) => builder(_), transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child));
      case 'scale':
        return PageRouteBuilder<T>(pageBuilder: (_, __, ___) => builder(_), transitionsBuilder: (_, anim, __, child) => ScaleTransition(scale: anim, child: child));
      default:
        return MaterialPageRoute<T>(builder: builder);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
