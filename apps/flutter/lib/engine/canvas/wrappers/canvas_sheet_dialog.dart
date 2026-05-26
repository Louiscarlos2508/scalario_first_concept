import 'package:flutter/material.dart';
import '../../canvas_registry/component_config.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';

class CanvasSheetDialog extends StatelessWidget {
  final ComponentConfig config;
  final BuildContext ctx;
  const CanvasSheetDialog({super.key, required this.config, required this.ctx});

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    return CanvasSheetDialog(config: config, ctx: ctx);
  }

  static void showSheet(BuildContext context, ComponentConfig config) {
    final r = ScalarioCanvasRegistry.instance;
    showModalBottomSheet(context: context, builder: (ctx) => r?.build(config, ctx) ?? const SizedBox.shrink());
  }

  static Future<String?> showDialog(BuildContext context, ComponentConfig config) {
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text(config.props['title'] as String? ?? ''),
      content: Text(config.props['message'] as String? ?? ''),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, 'confirm'), child: const Text('Confirmer')),
      ],
    ));
  }

  static void showSnackBar(BuildContext context, ComponentConfig config) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(config.props['message'] as String? ?? '')));
  }

  static Future<String?> showDrawer(BuildContext context, ComponentConfig config) {
    final r = ScalarioCanvasRegistry.instance;
    return showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: r?.build(config, ctx) ?? const SizedBox.shrink(),
    ));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
