import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'components/components.dart';
import 'core/theme/scalario_theme.dart';
import 'engine/canvas_registry/component_config.dart';

void main() {
  runApp(const ScalarioWidgetbook());
}

class ScalarioWidgetbook extends StatelessWidget {
  const ScalarioWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        MaterialThemeAddon(themes: [
          WidgetbookTheme(name: 'Light', data: ScalarioTheme.light()),
          WidgetbookTheme(name: 'Dark', data: ScalarioTheme.dark()),
        ]),
        TextScaleAddon(
          min: 0.85,
          max: 1.3,
        ),
      ],
      directories: [
        WidgetbookFolder(
          name: 'Data Display',
          children: [
            _kpiCardComponent(),
            _dataTableComponent(),
            _chartBarComponent(),
            _chartPieComponent(),
            _statCardComponent(),
            _documentPreviewComponent(),
          ],
        ),
        WidgetbookFolder(
          name: 'Feedback',
          children: [
            _alertBannerComponent(),
            _syncStatusBarComponent(),
          ],
        ),
        WidgetbookFolder(
          name: 'Actions',
          children: [
            _buttonComponent(),
            _fabComponent(),
          ],
        ),
        WidgetbookFolder(
          name: 'Inputs',
          children: [
            _formComponent(),
          ],
        ),
        WidgetbookFolder(
          name: 'Lists',
          children: [
            _listTileComponent(),
          ],
        ),
      ],
    );
  }
}

WidgetbookComponent _kpiCardComponent() {
  return WidgetbookComponent(
    name: 'KPICard',
    useCases: [
      WidgetbookUseCase(
        name: 'Default — normal',
        builder: (_) => const KPICard(label: 'CA du jour', value: '142 500', unit: 'FCFA'),
      ),
      WidgetbookUseCase(
        name: 'Default — warning',
        builder: (_) => const KPICard(label: 'Stock critique', value: '3', unit: 'unites', status: KpiStatus.warning),
      ),
      WidgetbookUseCase(
        name: 'Default — critical',
        builder: (_) => const KPICard(label: 'Pertes', value: '47 200', unit: 'FCFA', status: KpiStatus.critical),
      ),
      WidgetbookUseCase(
        name: 'Loading',
        builder: (_) => KPICard.loading(label: 'CA du jour'),
      ),
      WidgetbookUseCase(
        name: 'Empty',
        builder: (_) => KPICard.empty('Aucune vente'),
      ),
      WidgetbookUseCase(
        name: 'Error',
        builder: (_) => KPICard.error(label: 'KPI', message: 'Erreur de chargement'),
      ),
    ],
  );
}

WidgetbookComponent _dataTableComponent() {
  return WidgetbookComponent(
    name: 'DataTable',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (_) => ScalarioDataTable<String>(
          columns: [
            DataColumnConfig<String>(key: 'a', label: 'Col A', cellBuilder: (s) => s),
            DataColumnConfig<String>(key: 'b', label: 'Col B', cellBuilder: (s) => s),
            DataColumnConfig<String>(key: 'c', label: 'Col C', cellBuilder: (s) => s),
          ],
          rows: const ['R1', 'R2', 'R3'],
          defaultSortKey: 'a',
        ),
      ),
    ],
  );
}

WidgetbookComponent _chartBarComponent() {
  return WidgetbookComponent(
    name: 'ChartBar',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (_) => ChartBar(
          title: 'Ventes par jour',
          data: const [
            ChartDataPoint(label: 'Lun', value: 42),
            ChartDataPoint(label: 'Mar', value: 55),
            ChartDataPoint(label: 'Mer', value: 38),
            ChartDataPoint(label: 'Jeu', value: 62),
            ChartDataPoint(label: 'Ven', value: 78),
          ],
        ),
      ),
    ],
  );
}

WidgetbookComponent _chartPieComponent() {
  return WidgetbookComponent(
    name: 'ChartPie',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (ctx) => ChartPie.fromConfig(
          ComponentConfig(type: 'ChartPie', variant: 'default', props: {'title': 'Repartition'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Donut',
        builder: (ctx) => ChartPie.fromConfig(
          ComponentConfig(type: 'ChartPie', variant: 'donut', props: {'title': 'Parts'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Mini-legend',
        builder: (ctx) => ChartPie.fromConfig(
          ComponentConfig(type: 'ChartPie', variant: 'mini-legend', props: {'title': 'Resume'}),
          ctx,
        ),
      ),
    ],
  );
}

WidgetbookComponent _statCardComponent() {
  return WidgetbookComponent(
    name: 'StatCard',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (ctx) => StatCard.fromConfig(
          ComponentConfig(type: 'StatCard', variant: 'default', props: {'label': 'Ventes', 'value': '142'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Trend-up',
        builder: (ctx) => StatCard.fromConfig(
          ComponentConfig(type: 'StatCard', variant: 'trend-up', props: {'label': 'CA', 'value': '520K', 'delta': '+12%'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Trend-down',
        builder: (ctx) => StatCard.fromConfig(
          ComponentConfig(type: 'StatCard', variant: 'trend-down', props: {'label': 'Pertes', 'value': '47K', 'delta': '-5%'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Flat',
        builder: (ctx) => StatCard.fromConfig(
          ComponentConfig(type: 'StatCard', variant: 'flat', props: {'label': 'Stock', 'value': '320'}),
          ctx,
        ),
      ),
    ],
  );
}

WidgetbookComponent _documentPreviewComponent() {
  return WidgetbookComponent(
    name: 'DocumentPreview',
    useCases: [
      WidgetbookUseCase(
        name: 'Inline',
        builder: (ctx) => DocumentPreview.fromConfig(
          ComponentConfig(type: 'DocumentPreview', variant: 'inline', props: {'title': 'Facture #001'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Card',
        builder: (ctx) => DocumentPreview.fromConfig(
          ComponentConfig(type: 'DocumentPreview', variant: 'card', props: {'title': 'Facture #002'}),
          ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Thumbnail',
        builder: (ctx) => DocumentPreview.fromConfig(
          ComponentConfig(type: 'DocumentPreview', variant: 'thumbnail', props: {'title': 'Doc'}),
          ctx,
        ),
      ),
    ],
  );
}

WidgetbookComponent _alertBannerComponent() {
  return WidgetbookComponent(
    name: 'AlertBanner',
    useCases: [
      WidgetbookUseCase(
        name: 'Info',
        builder: (_) => const AlertBanner(type: AlertType.info, message: 'Mise a jour disponible'),
      ),
      WidgetbookUseCase(
        name: 'Success',
        builder: (_) => const AlertBanner(type: AlertType.success, message: 'Synchronisation reussie'),
      ),
      WidgetbookUseCase(
        name: 'Warning',
        builder: (_) => const AlertBanner(type: AlertType.warning, message: 'Stock faible — 3 produits'),
      ),
      WidgetbookUseCase(
        name: 'Danger',
        builder: (_) => const AlertBanner(type: AlertType.critical, message: 'Echec de paiement'),
      ),
    ],
  );
}

WidgetbookComponent _syncStatusBarComponent() {
  return WidgetbookComponent(
    name: 'SyncStatusBar',
    useCases: [
      WidgetbookUseCase(
        name: 'Synced',
        builder: (ctx) => SyncStatusBar.fromConfig(
          ComponentConfig(type: 'SyncStatusBar', variant: 'synced', props: {}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Syncing',
        builder: (ctx) => SyncStatusBar.fromConfig(
          ComponentConfig(type: 'SyncStatusBar', variant: 'syncing', props: {}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Conflict',
        builder: (ctx) => SyncStatusBar.fromConfig(
          ComponentConfig(type: 'SyncStatusBar', variant: 'conflict', props: {}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Offline',
        builder: (ctx) => SyncStatusBar.fromConfig(
          ComponentConfig(type: 'SyncStatusBar', variant: 'offline', props: {}), ctx,
        ),
      ),
    ],
  );
}

WidgetbookComponent _buttonComponent() {
  return WidgetbookComponent(
    name: 'Button',
    useCases: [
      WidgetbookUseCase(
        name: 'Primary',
        builder: (ctx) => ScalarioButton.fromConfig(
          ComponentConfig(type: 'ScalarioButton', variant: 'primary', props: {'label': 'Enregistrer'}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Secondary',
        builder: (ctx) => ScalarioButton.fromConfig(
          ComponentConfig(type: 'ScalarioButton', variant: 'secondary', props: {'label': 'Annuler'}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Ghost',
        builder: (ctx) => ScalarioButton.fromConfig(
          ComponentConfig(type: 'ScalarioButton', variant: 'ghost', props: {'label': 'Aide'}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Danger',
        builder: (ctx) => ScalarioButton.fromConfig(
          ComponentConfig(type: 'ScalarioButton', variant: 'danger', props: {'label': 'Supprimer'}), ctx,
        ),
      ),
      WidgetbookUseCase(
        name: 'Icon-only',
        builder: (ctx) => ScalarioButton.fromConfig(
          ComponentConfig(type: 'ScalarioButton', variant: 'icon-only', props: {}), ctx,
        ),
      ),
    ],
  );
}

WidgetbookComponent _fabComponent() {
  return WidgetbookComponent(
    name: 'FAB',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (_) => const ScalarioFAB(icon: Icons.add, label: 'Ajouter'),
      ),
      WidgetbookUseCase(
        name: 'Mini',
        builder: (_) => SizedBox(
          width: 40, height: 40,
          child: FloatingActionButton.small(onPressed: () {}, child: const Icon(Icons.add)),
        ),
      ),
      WidgetbookUseCase(
        name: 'Extended',
        builder: (_) => FloatingActionButton.extended(
          onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Nouvelle vente'),
        ),
      ),
    ],
  );
}

WidgetbookComponent _formComponent() {
  return WidgetbookComponent(
    name: 'FormField',
    useCases: [
      WidgetbookUseCase(
        name: 'Form Section',
        builder: (_) => const FormSection(title: 'Formulaire', children: []),
      ),
    ],
  );
}

WidgetbookComponent _listTileComponent() {
  return WidgetbookComponent(
    name: 'ListTile',
    useCases: [
      WidgetbookUseCase(
        name: 'Default',
        builder: (_) => const ScalarioListTile(title: 'Produit A', subtitle: '500 FCFA'),
      ),
      WidgetbookUseCase(
        name: 'With-avatar',
        builder: (_) => ListTile(
          leading: const CircleAvatar(child: Text('P')),
          title: const Text('Produit B'),
          subtitle: const Text('12 unites'),
        ),
      ),
      WidgetbookUseCase(
        name: 'With-badge',
        builder: (_) => ListTile(
          title: const Text('Alertes'),
          trailing: Badge(label: const Text('3')),
        ),
      ),
      WidgetbookUseCase(
        name: 'Dense',
        builder: (_) => const ListTile(
          dense: true,
          title: Text('Compact'),
          subtitle: Text('Haute densite'),
        ),
      ),
    ],
  );
}
