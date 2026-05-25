import 'package:flutter/material.dart';

import '../../../components/feedback/alert_banner.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../screen_config.dart';
import 'dashboard_layout.dart';

/// Fallback pour un `layoutType` non reconnu.
///
/// Rend : AlertBanner info en haut + DashboardLayout comme variante de secours.
/// Le warning est loggué par [ScalarioCanvasLayout._unknown] avant d'instancier ce widget.
class UnknownLayout extends StatelessWidget {
  const UnknownLayout({
    super.key,
    required this.layoutType,
    required this.config,
    required this.registry,
  });

  final String layoutType;
  final ScreenConfig config;
  final ScalarioCanvasRegistry registry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AlertBanner(
          type: AlertType.info,
          message: "Layout '$layoutType' non reconnu, mode dashboard",
        ),
        Expanded(
          child: DashboardLayout(config: config, registry: registry),
        ),
      ],
    );
  }
}
