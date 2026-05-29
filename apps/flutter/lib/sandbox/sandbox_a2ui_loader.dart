// Loader A2UI pour la sandbox.
//
// Les fixtures A2UI sont des listes de messages (createSurface,
// updateComponents, updateDataModel) qui simulent la sortie du MindEngine.
// Le loader les parse et les retourne directement sous forme de
// `List<Map<String, dynamic>>` consommable par `A2UICanvas(initialMessages: ...)`.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class A2uiSandboxLoader {
  const A2uiSandboxLoader();

  static const String _assetPrefix = 'assets/sandbox/';

  List<String> listFixtures() => kA2uiFixtureIds;

  String describePath(String fixtureId) => '$_assetPrefix$fixtureId.json';

  Future<List<Map<String, dynamic>>> load(String fixtureId) async {
    final raw = await rootBundle.loadString(describePath(fixtureId));
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}

/// IDs des fixtures A2UI disponibles dans la sandbox.
///
/// Chaque fixture est un fichier JSON contenant un tableau de messages A2UI.
/// Préfixées par "a2ui_" pour les distinguer des fixtures BDUI.
const List<String> kA2uiFixtureIds = <String>[
  'a2ui_dashboard',
];
