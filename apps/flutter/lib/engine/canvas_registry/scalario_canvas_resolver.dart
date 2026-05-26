import '../canvas_rule/user_context.dart';

/// Contexte d'execution pour la resolution de variante 'auto'.
class VariantContext {
  const VariantContext({
    required this.screenWidth,
    required this.userContext,
    this.childCount = 0,
  });

  final double screenWidth;
  final UserContext? userContext;
  final int childCount;
}

typedef VariantHook = String Function(VariantContext ctx);

/// Resolution globale de variante pour le Scalario Canvas.
///
/// Chaque composant DS peut enregistrer un hook de resolution specifique.
/// Si aucun hook n'est enregistre, les regles globales s'appliquent :
/// - screen < 600px → 'compact'
/// - sinon → 'default'
class ScalarioCanvasResolver {
  ScalarioCanvasResolver._();

  static final Map<String, VariantHook> _hooks = {};

  static void registerHook(String componentType, VariantHook hook) {
    _hooks[componentType] = hook;
  }

  static void unregisterHook(String componentType) {
    _hooks.remove(componentType);
  }

  static String resolveVariant(
    String variant, {
    String? component,
    double screenWidth = 800,
    UserContext? userContext,
    int childCount = 0,
  }) {
    if (variant != 'auto') return variant;

    final ctx = VariantContext(
      screenWidth: screenWidth,
      userContext: userContext,
      childCount: childCount,
    );

    if (component != null) {
      final hook = _hooks[component];
      if (hook != null) return hook(ctx);
    }

    if (screenWidth < 600) return 'compact';
    return 'default';
  }
}
