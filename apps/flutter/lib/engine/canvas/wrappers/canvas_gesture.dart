import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';

class CanvasGesture extends StatelessWidget {
  final ComponentConfig config;
  final Widget child;
  const CanvasGesture({super.key, required this.config, required this.child});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasGesture(config: config, child: const SizedBox.shrink());
  }

  static Widget wrap(ComponentConfig config, Widget child) {
    final gestures = config.props['gestures'] as Map<String, dynamic>?;
    if (gestures == null) return child;

    Widget wrapped = child;
    if (gestures.containsKey('swipe_left')) {
      wrapped = Dismissible(
        key: config.id != null ? ValueKey(config.id) : UniqueKey(),
        direction: DismissDirection.endToStart,
        background: Container(color: _colors['warning']),
        onDismissed: (_) {},
        child: wrapped,
      );
    }
    if (gestures.containsKey('swipe_right')) {
      wrapped = Dismissible(
        key: config.id != null ? ValueKey('${config.id}_r') : UniqueKey(),
        direction: DismissDirection.startToEnd,
        background: Container(color: _colors['success']),
        onDismissed: (_) {},
        child: wrapped,
      );
    }
    if (gestures.containsKey('long_press')) {
      wrapped = GestureDetector(onLongPress: () {}, child: wrapped);
    }
    return wrapped;
  }

  @override
  Widget build(BuildContext context) => child;

  static const _colors = {'warning': Colors.orange, 'success': Colors.green};
}
