import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import '../component_registry/component_registry.dart';
import 'layouts/dashboard_layout.dart';
import 'layouts/detail_layout.dart';
import 'layouts/form_layout.dart';
import 'layouts/list_layout.dart';
import 'layouts/unknown_layout.dart';
import 'screen_config.dart';

export 'breakpoints.dart';
export 'layouts/dashboard_layout.dart';
export 'layouts/detail_layout.dart';
export 'layouts/form_layout.dart';
export 'layouts/list_layout.dart';
export 'layouts/unknown_layout.dart';
export 'screen_config.dart';

/// Résout un `layoutType` string + `ScreenConfig` → widget Flutter structuré.
///
/// Layouts supportés : `dashboard`, `list`, `form`, `detail`.
/// Tout autre string → [UnknownLayout] + log warning level 900.
///
/// Sans état — instance unique enregistrée via `get_it`.
/// Aucun import `package:scalario/features/...` dans ce package (AC-08).
@immutable
final class LayoutResolver {
  const LayoutResolver({required this.registry});

  final ComponentRegistry registry;

  Widget resolve(
    String layoutType,
    ScreenConfig config,
    BuildContext ctx,
  ) {
    return switch (layoutType) {
      'dashboard' => DashboardLayout(config: config, registry: registry),
      'list' => ListLayout(config: config, registry: registry),
      'form' => FormLayout(config: config, registry: registry),
      'detail' => DetailLayout(config: config, registry: registry),
      _ => _unknown(layoutType, config),
    };
  }

  Widget _unknown(String layoutType, ScreenConfig config) {
    developer.log(
      'Unknown layout type "$layoutType", falling back to dashboard',
      name: 'BDUI.LayoutResolver',
      level: 900,
    );
    return UnknownLayout(
      layoutType: layoutType,
      config: config,
      registry: registry,
    );
  }
}
