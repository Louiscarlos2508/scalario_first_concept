import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';

/// FAB Scalario — wrappe `FloatingActionButton(.extended)` Material 3.
///
/// **Spec source :** `design-process/D-Design-System/components/05-actions.md`
/// (variante FAB) + `Theme.of(context).floatingActionButtonTheme` (STORY-002).
///
/// **Important :** ce widget **ne se positionne pas lui-même**. Il doit être
/// placé dans `Scaffold(floatingActionButton: ...)` par le parent (le
/// `ScalarioCanvasLayout` BDUI). C'est conforme à l'API Flutter idiomatique :
/// le FAB est positionné par le Scaffold, pas par le widget lui-même.
///
/// **États supportés :** Normal, Disabled (`onPressed: null`), Loading
/// (spinner remplace l'icône, callback ignoré), Extended (avec `label`).
class ScalarioFAB extends StatelessWidget {
  const ScalarioFAB({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.loading = false,
    this.heroTag,
  });

  /// Construit un `ScalarioFAB` depuis les props d'un `ComponentConfig` BDUI.
  ///
  /// Utilisé par le `ScalarioCanvasRegistry` (STORY-005). Délègue à [fromJson].
  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    final variant = ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'ScalarioFAB',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    try {
      final fab = ScalarioFAB.fromJson(config.props);
      if (variant == 'mini') {
        return SizedBox(
          width: 40, height: 40,
          child: FloatingActionButton.small(onPressed: fab.onPressed, child: Icon(fab.icon)),
        );
      }
      if (variant == 'extended') {
        return FloatingActionButton.extended(
          onPressed: fab.onPressed, icon: Icon(fab.icon), label: Text(config.props['label'] as String? ?? ''),
        );
      }
      return fab;
    } on FormatException {
      return ScalarioFAB(icon: Icons.add, label: config.props['label'] as String?);
    }
  }

  factory ScalarioFAB.fromJson(Map<String, dynamic> json) {
    final dynamic codePoint = json['icon_code_point'];
    if (codePoint is! int) {
      throw const FormatException(
          "ScalarioFAB: 'icon_code_point' (int) requis");
    }
    return ScalarioFAB(
      icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
      label: json['label'] as String?,
      loading: json['loading'] as bool? ?? false,
    );
  }

  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final bool loading;

  /// Tag de transition Hero — par défaut `null` (laisse Flutter générer).
  /// À fournir si plusieurs FAB cohabitent dans la même Navigator.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final VoidCallback? effectiveOnPressed = loading ? null : onPressed;
    final bool disabled = effectiveOnPressed == null;

    final Widget iconChild = loading
        ? SizedBox(
            width: ScalarioIconSize.sm,
            height: ScalarioIconSize.sm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(scheme.onPrimaryContainer),
            ),
          )
        : Icon(icon);

    Widget fab;
    if (label != null) {
      fab = FloatingActionButton.extended(
        onPressed: effectiveOnPressed,
        heroTag: heroTag,
        icon: iconChild,
        label: Text(label!),
      );
    } else {
      fab = FloatingActionButton(
        onPressed: effectiveOnPressed,
        heroTag: heroTag,
        child: iconChild,
      );
    }

    if (disabled && !loading) {
      // État disabled visuel — opacité 0.5, pas de ripple (onPressed null
      // suffit pour désactiver le ripple Material).
      return Opacity(opacity: 0.5, child: fab);
    }
    return fab;
  }
}
