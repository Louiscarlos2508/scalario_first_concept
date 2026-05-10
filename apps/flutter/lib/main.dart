// Scalario — entrée Flutter.
//
// STORY-002 : `MaterialApp` consomme `ScalarioTheme.light()` /
// `ScalarioTheme.dark()` avec `ThemeMode.system` (l'OS décide). Le thème est
// entièrement construit depuis les tokens (STORY-001) ; aucun override local.

import 'package:flutter/material.dart';

import 'core/design_system/tokens/tokens.dart';
import 'core/theme/scalario_theme.dart';
import 'core/theme/theme_extensions.dart';

void main() {
  runApp(const ScalarioApp());
}

class ScalarioApp extends StatelessWidget {
  const ScalarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      theme: ScalarioTheme.light(),
      darkTheme: ScalarioTheme.dark(),
      // Explicite (= défaut MaterialApp) — AC-21 exige le wiring système.
      // ignore: avoid_redundant_argument_values
      themeMode: ThemeMode.system,
      home: const _ThemeSmokePage(),
    );
  }
}

/// Page de smoke-test du thème — affiche un échantillon des composants M3
/// pour valider visuellement le wiring tokens → ThemeData.
class _ThemeSmokePage extends StatelessWidget {
  const _ThemeSmokePage();

  @override
  Widget build(BuildContext context) {
    final ScalarioColorsExtension semantic =
        Theme.of(context).extension<ScalarioColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scalario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'ThemeData Scalario chargé',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: ScalarioSpacing.space2),
            Text(
              'Material 3 + tokens — light & dark',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: ScalarioSpacing.space6),
            FilledButton(
              onPressed: () {},
              child: const Text('Action primaire'),
            ),
            const SizedBox(height: ScalarioSpacing.space2),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Action secondaire'),
            ),
            const SizedBox(height: ScalarioSpacing.space2),
            TextButton(
              onPressed: () {},
              child: const Text('Action ghost'),
            ),
            const SizedBox(height: ScalarioSpacing.space6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(ScalarioSpacing.space4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      ScalarioIcons.stateSuccess,
                      color: semantic.synced,
                    ),
                    const SizedBox(width: ScalarioSpacing.space2),
                    const Expanded(
                      child: Text('Sync OK · 14:32'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: ScalarioSpacing.space4),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Recherche',
                hintText: 'Tapez pour filtrer…',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
