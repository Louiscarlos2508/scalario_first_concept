// Run (standalone):  flutter run --target=lib/core/platform/_platform_capabilities_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              STORY-012 (Multi-plateforme Flutter) — visualise les flags runtime.

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../design_system/tokens/tokens.dart';
import '../theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'platform.dart';

PreviewThemeData scalarioPlatformCapabilitiesThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioPlatformCapabilitiesWrap(Widget child) => Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ScalarioSpacing.space4),
          child: child,
        ),
      ),
    );

@Preview(
  name: 'Platform Capabilities',
  theme: scalarioPlatformCapabilitiesThemes,
  wrapper: scalarioPlatformCapabilitiesWrap,
)
Widget previewPlatformCapabilities() => const _PlatformCapabilitiesContent();

class _PlatformCapabilitiesContent extends StatelessWidget {
  const _PlatformCapabilitiesContent();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final capabilities = PlatformCapabilities.snapshot();
    final storage = createPlatformStorage();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Platform Capabilities', style: theme.textTheme.headlineMedium),
        const SizedBox(height: ScalarioSpacing.space3),
        _InfoRow(label: 'name', value: PlatformInfo.name),
        _InfoRow(
          label: 'isMobile / isDesktop / isWeb',
          value:
              '${PlatformInfo.isMobile} / ${PlatformInfo.isDesktop} / ${PlatformInfo.isWeb}',
        ),
        _InfoRow(
          label: 'isMobileWeb / isDesktopWeb',
          value:
              '${PlatformInfo.isMobileWeb(context)} / ${PlatformInfo.isDesktopWeb(context)}',
        ),
        _InfoRow(
          label: 'viewport',
          value: '${size.width.toStringAsFixed(0)}×${size.height.toStringAsFixed(0)}',
        ),
        _InfoRow(label: 'storage.backend', value: storage.backend),
        _InfoRow(label: 'storage.location', value: storage.location),
        const Divider(height: ScalarioSpacing.space6),
        Text('Capabilities', style: theme.textTheme.titleMedium),
        const SizedBox(height: ScalarioSpacing.space2),
        for (final entry in capabilities.entries)
          _InfoRow(label: entry.key, value: entry.value ? '✓' : '✗'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ScalarioSpacing.space1),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(
              flex: 2,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'Platform Capabilities',
      child: _PlatformCapabilitiesContent(),
    ));
