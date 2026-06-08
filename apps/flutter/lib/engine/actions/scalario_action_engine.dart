import 'package:flutter/material.dart';
import '../canvas_registry/bdui_action.dart';

/// Moteur de workflow côté client.
/// Exécute un tableau d'actions (séquentiel).
class ScalarioActionEngine {
  static Future<void> execute(BuildContext context, List<BduiAction> actions) async {
    for (final action in actions) {
      await _executeSingle(context, action);
    }
  }

  static Future<void> _executeSingle(BuildContext context, BduiAction action) async {
    switch (action) {
      case BduiNavigateAction():
        debugPrint('ActionEngine: Navigate to ${action.screen}');
        // TODO: Mettre en place le routeur (ex: GoRouter)
        break;
      case BduiApiCallAction():
        debugPrint('ActionEngine: API Call ${action.method} ${action.endpoint}');
        // Simulation d'un appel API avec latence pour tester l'état asynchrone
        await Future.delayed(const Duration(milliseconds: 800));
        break;
      case BduiToastAction():
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action.messageKey ?? 'Notification'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(milliseconds: action.durationMs ?? 2000),
            ),
          );
        }
        break;
      case BduiLocalAction():
        debugPrint('ActionEngine: Local Action ${action.action}');
        break;
      default:
        debugPrint('ActionEngine: Unhandled action type ${action.runtimeType}');
    }
  }
}
