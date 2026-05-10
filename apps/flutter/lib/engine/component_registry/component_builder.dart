import 'package:flutter/widgets.dart';

import 'component_config.dart';

/// Signature publique d'un builder BDUI.
///
/// AC-03 : typedef public, paramètres (`ComponentConfig`, `BuildContext`).
///
/// Chaque DS component livré dans le registry expose une function de ce
/// type. Le registry ne connaît que cette signature — il ne sait rien
/// du widget concret retourné.
///
/// Les builders ne doivent jamais throw : toute exception doit être
/// gérée localement et un widget fallback doit être retourné.
typedef ComponentBuilder = Widget Function(
  ComponentConfig config,
  BuildContext ctx,
);
