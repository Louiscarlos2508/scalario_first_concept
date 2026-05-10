// Run (standalone):  flutter run --target=lib/components/actions/_scalario_fab_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/05-actions.md (FAB)

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'scalario_fab.dart';

PreviewThemeData scalarioFABThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioFABWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

@Preview(name: 'Normal', theme: scalarioFABThemes, wrapper: scalarioFABWrap)
Widget previewFABNormal() => ScalarioFAB(
      icon: ScalarioIcons.actionAdd,
      onPressed: () {},
      heroTag: 'fab-normal',
    );

@Preview(name: 'Extended avec label', theme: scalarioFABThemes, wrapper: scalarioFABWrap)
Widget previewFABExtended() => ScalarioFAB(
      icon: ScalarioIcons.actionAdd,
      label: 'Encaisser',
      onPressed: () {},
      heroTag: 'fab-extended',
    );

@Preview(name: 'Loading', theme: scalarioFABThemes, wrapper: scalarioFABWrap)
Widget previewFABLoading() => const ScalarioFAB(
      icon: ScalarioIcons.actionAdd,
      loading: true,
      heroTag: 'fab-loading',
    );

@Preview(name: 'Disabled', theme: scalarioFABThemes, wrapper: scalarioFABWrap)
Widget previewFABDisabled() => const ScalarioFAB(
      icon: ScalarioIcons.actionAdd,
      heroTag: 'fab-disabled',
    );

class _ScalarioFABShowcase extends StatelessWidget {
  const _ScalarioFABShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Normal', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewFABNormal(),
            const SizedBox(height: ScalarioSpacing.space6),
            Text('Extended avec label', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewFABExtended(),
            const SizedBox(height: ScalarioSpacing.space6),
            Text('Loading', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewFABLoading(),
            const SizedBox(height: ScalarioSpacing.space6),
            Text('Disabled', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewFABDisabled(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'ScalarioFAB Showcase',
      child: _ScalarioFABShowcase(),
    ));
