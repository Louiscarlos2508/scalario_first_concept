// Run (standalone):  flutter run --target=lib/components/feedback/_alert_banner_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/01-feedback.md (AlertBanner, lignes 14-68)

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'alert_banner.dart';

PreviewThemeData scalarioAlertBannerThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioAlertBannerWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

// Auto-dismiss désactivé en preview (autoDismissMs: null) — sinon le banner
// disparaît au render et le preview reste vide.

@Preview(name: 'Critical', theme: scalarioAlertBannerThemes, wrapper: scalarioAlertBannerWrap)
Widget previewAlertBannerCritical() => const AlertBanner(
      type: AlertType.critical,
      message: 'Stock de tomates épuisé — approvisionnement urgent requis.',
    );

@Preview(name: 'Warning', theme: scalarioAlertBannerThemes, wrapper: scalarioAlertBannerWrap)
Widget previewAlertBannerWarning() => const AlertBanner(
      type: AlertType.warning,
      message: 'Stock d\'avocat faible — 3 unités restantes.',
    );

@Preview(name: 'Success', theme: scalarioAlertBannerThemes, wrapper: scalarioAlertBannerWrap)
Widget previewAlertBannerSuccess() => const AlertBanner(
      type: AlertType.success,
      message: 'Synchronisation réussie — toutes les données sont à jour.',
    );

@Preview(name: 'Info', theme: scalarioAlertBannerThemes, wrapper: scalarioAlertBannerWrap)
Widget previewAlertBannerInfo() => const AlertBanner(
      type: AlertType.info,
      message: 'Mise à jour disponible — redémarrez l\'application.',
    );

@Preview(name: 'Critical avec action', theme: scalarioAlertBannerThemes, wrapper: scalarioAlertBannerWrap)
Widget previewAlertBannerCriticalAction() => AlertBanner(
      type: AlertType.critical,
      message: 'Stock critique — 2 articles en rupture imminente.',
      actionLabel: 'Voir stock',
      onAction: () {},
    );

class _AlertBannerShowcase extends StatelessWidget {
  const _AlertBannerShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            previewAlertBannerCritical(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewAlertBannerWarning(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewAlertBannerSuccess(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewAlertBannerInfo(),
            const SizedBox(height: ScalarioSpacing.space4),
            previewAlertBannerCriticalAction(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'AlertBanner Showcase',
      child: _AlertBannerShowcase(),
    ));
