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

const List<String> kA2uiFixtureIds = <String>[];