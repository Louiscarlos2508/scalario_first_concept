// Dispatcheur d'actions pour la sandbox A2UI.
//
// Traduit les actions déclaratives (ex: `{engine: "flow", action: "nouvelle_vente"}`)
// en callbacks exécutables. Pour l'instant : log + SnackBar.
// Sera connecté au Flow Engine / Action Engine plus tard.

import 'package:flutter/material.dart';

import '../engine/canvas_registry/bdui_action.dart';
import 'sandbox_console.dart';

class SandboxActionDispatcher {
  SandboxActionDispatcher({
    required this.console,
    required this.scaffoldMessenger,
  });

  final SandboxConsoleController console;
  final ScaffoldMessengerState scaffoldMessenger;

  void dispatch(Map<String, dynamic> action) {
    final engine = action['engine'] as String? ?? 'unknown';
    final actionName = action['action'] as String? ?? 'unknown';
    final props = action['props'] as Map<String, dynamic>? ?? {};

    console.log(
      SandboxLogLevel.action,
      'Action',
      '$engine.$actionName ${props.isNotEmpty ? "props=$props" : ""}',
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Action: $engine.$actionName'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> dispatchBdui(BuildContext context, List<BduiAction> actions) async {
    for (final action in actions) {
      console.log(
        SandboxLogLevel.action,
        'Action (BDUI)',
        'type=${action.runtimeType} trigger=${action.trigger}',
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Sandbox Action: ${action.runtimeType}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Simulate network latency to test the new loading state on buttons
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }
}

