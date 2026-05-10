// Run (standalone):  flutter run --target=lib/showcases/_pos_commercial_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/ — composition POS Commercial

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../components/actions/scalario_fab.dart';
import '../components/data_display/kpi_card.dart';
import '../components/lists/scalario_list_tile.dart';
import '../core/design_system/tokens/tokens.dart';
import '../core/theme/scalario_theme.dart';
import '_showcase_app.dart';

PreviewThemeData scalarioPOSCommercialThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioPOSCommercialWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

// Données fictives — aucun client réel (AC sécurité).
const List<({String name, String qty, String price, String total})> _mockArticles =
    <({String name, String qty, String price, String total})>[
  (name: 'Tomates', qty: '2 kg', price: '500/kg', total: '1 000 FCFA'),
  (name: 'Avocat', qty: '3 pcs', price: '600/pc', total: '1 800 FCFA'),
  (name: 'Igname', qty: '1 kg', price: '700/kg', total: '700 FCFA'),
  (name: 'Piment doux', qty: '0,5 kg', price: '800/kg', total: '400 FCFA'),
  (name: 'Gingembre', qty: '0,2 kg', price: '1 500/kg', total: '300 FCFA'),
];

@Preview(name: 'POS Commercial', theme: scalarioPOSCommercialThemes, wrapper: scalarioPOSCommercialWrap)
Widget previewPOSCommercial() => const _POSCommercialContent();

class _POSCommercialContent extends StatelessWidget {
  const _POSCommercialContent();

  static const double _totalFCFA = 4200;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Liste articles du panier
          Text('Panier en cours', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: ScalarioSpacing.space3),
          for (final ({String name, String qty, String price, String total}) article
              in _mockArticles)
            ScalarioListTile(
              title: article.name,
              subtitle: '${article.qty} · ${article.price}',
              trailing: Text(article.total, style: ScalarioTypography.bodyMono),
            ),
          const SizedBox(height: ScalarioSpacing.space6),
          // Résumé panier
          const KPICard(
            label: 'Total panier',
            value: '4 200',
            unit: 'FCFA',
            delta: '5 articles',
          ),
          const SizedBox(height: ScalarioSpacing.space6),
          // FAB Encaisser
          Align(
            alignment: Alignment.centerRight,
            child: ScalarioFAB(
              icon: ScalarioIcons.bizCash,
              label: 'Encaisser ${_totalFCFA.toStringAsFixed(0)} FCFA',
              onPressed: () {},
              heroTag: 'pos-encaisser',
            ),
          ),
        ],
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'POS Commercial',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ScalarioSpacing.space4),
        child: _POSCommercialContent(),
      ),
    ));
