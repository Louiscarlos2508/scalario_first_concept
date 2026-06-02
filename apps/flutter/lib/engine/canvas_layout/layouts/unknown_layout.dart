import 'package:flutter/material.dart';

import '../../../components/feedback/alert_banner.dart';
import '../../canvas_registry/scalario_canvas_registry.dart';
import '../../canvas_registry/screen_layout.dart';
import '../../canvas_layout/slot_layout.dart';
import '../screen_config.dart';

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
          child: SlotLayout(
            layout: ScreenLayout.fromJson({
              'layout': 'dashboard',
              'slots': {'main': {'zone': 'main', 'position': 'main', 'scroll': true}},
            }),
            zones: config.zones,
            registry: registry,
          ),
        ),
      ],
    );
  }
}