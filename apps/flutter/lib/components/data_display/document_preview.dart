import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

class DocumentPreview extends StatelessWidget {
  const DocumentPreview._({required this.props, required this.variant});

  final Map<String, dynamic> props;
  final String variant;

  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'DocumentPreview',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    return DocumentPreview._(props: config.props, variant: config.variant);
  }

  @override
  Widget build(BuildContext context) {
    final title = props['title'] as String? ?? 'Document';
    switch (variant) {
      case 'card':
        return Card(
          child: ListTile(
            leading: const Icon(Icons.description),
            title: Text(title, style: ScalarioTypography.caption),
          ),
        );
      case 'fullscreen':
        return Container(
          color: ScalarioColors.bgCard,
          child: Center(
            child: Column(children: [
              Icon(Icons.description, size: 64, color: ScalarioColors.textDisabled),
              Text(title, style: ScalarioTypography.caption),
            ]),
          ),
        );
      case 'thumbnail':
        return Container(
          width: 80, height: 100,
          decoration: BoxDecoration(
            color: ScalarioColors.bgCard,
            borderRadius: BorderRadius.circular(ScalarioRadius.sm),
          ),
          child: const Icon(Icons.picture_as_pdf, color: ScalarioColors.textDisabled),
        );
      default:
        return ListTile(
          leading: const Icon(Icons.description),
          title: Text(title, style: ScalarioTypography.caption),
          dense: true,
        );
    }
  }
}
