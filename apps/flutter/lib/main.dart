// Scalario — entrée minimale.
//
// Cette story (STORY-001) ne livre que les **tokens**. La construction du
// `ThemeData` (light + dark, ColorScheme, TextTheme, ThemeExtensions) est
// scope STORY-002. On présente ici un Scaffold "Hello tokens" pour que
// `flutter run` boot, sans dupliquer la logique de thème.

import 'package:flutter/material.dart';

import 'core/design_system/tokens/tokens.dart';

void main() {
  runApp(const ScalarioApp());
}

class ScalarioApp extends StatelessWidget {
  const ScalarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Scalario',
      debugShowCheckedModeBanner: false,
      home: _TokensSmokePage(),
    );
  }
}

class _TokensSmokePage extends StatelessWidget {
  const _TokensSmokePage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ScalarioColors.bgPage,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(ScalarioSpacing.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Scalario',
                style: ScalarioTypography.display,
              ),
              const SizedBox(height: ScalarioSpacing.space2),
              Text(
                'Design tokens chargés ✓',
                style: ScalarioTypography.body,
              ),
              const SizedBox(height: ScalarioSpacing.space4),
              Icon(
                ScalarioIcons.stateSuccess,
                size: ScalarioIconSize.lg,
                color: ScalarioIcons.stateColor(ScalarioIcons.stateSuccess),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
