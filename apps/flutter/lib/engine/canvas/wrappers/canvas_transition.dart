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

    switch (transition) {
      case 'fade':
        return PageRouteBuilder<T>(
          pageBuilder: (context, anim1, anim2) => builder(context),
          transitionsBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
        );
      case 'scale':
        return PageRouteBuilder<T>(
          pageBuilder: (context, anim1, anim2) => builder(context),
          transitionsBuilder: (context, anim1, anim2, child) => ScaleTransition(scale: anim1, child: child),
        );
      default:
        return MaterialPageRoute<T>(builder: builder);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
