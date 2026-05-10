// Run (standalone):  flutter run --target=lib/components/data_display/_data_table_showcase.dart -d <device>
// Preview (IDE):     flutter widget-preview start  → ouvrir ce fichier
// Spec:              design-process/D-Design-System/components/02-data-display.md (DataTable, lignes 529-559)

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/scalario_theme.dart';
import '../../showcases/_showcase_app.dart';
import 'scalario_data_table.dart';

PreviewThemeData scalarioDataTableThemes() => PreviewThemeData(
      materialLight: ScalarioTheme.light(),
      materialDark: ScalarioTheme.dark(),
    );

Widget scalarioDataTableWrap(Widget child) => Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: child,
      ),
    );

// Mock data — noms ostensiblement fictifs (AC-25 sécurité).
class _Tenant {
  const _Tenant({required this.id, required this.name, required this.ca, required this.region});
  final String id;
  final String name;
  final String ca;
  final String region;
}

const List<_Tenant> _mockTenants = <_Tenant>[
  _Tenant(id: 'A01', name: 'Boutique Kouamé', ca: '120 000', region: 'Abidjan'),
  _Tenant(id: 'A02', name: 'Shop Aminata', ca: '87 500', region: 'Bouaké'),
  _Tenant(id: 'A03', name: 'Dépôt Tenant Démo', ca: '64 200', region: 'Daloa'),
  _Tenant(id: 'A04', name: 'Acme SARL', ca: '201 800', region: 'Abidjan'),
  _Tenant(id: 'A05', name: 'Marché Yopougon', ca: '38 900', region: 'Yopougon'),
];

List<DataColumnConfig<_Tenant>> get _columns => <DataColumnConfig<_Tenant>>[
      const DataColumnConfig<_Tenant>(
        key: 'id',
        label: 'ID',
        cellBuilder: _buildId,
      ),
      const DataColumnConfig<_Tenant>(
        key: 'name',
        label: 'Boutique',
        cellBuilder: _buildName,
      ),
      const DataColumnConfig<_Tenant>(
        key: 'ca',
        label: 'CA (FCFA)',
        cellBuilder: _buildCa,
        align: DataColumnAlign.right,
      ),
      const DataColumnConfig<_Tenant>(
        key: 'region',
        label: 'Région',
        cellBuilder: _buildRegion,
        sortable: false,
      ),
    ];

String _buildId(_Tenant t) => t.id;
String _buildName(_Tenant t) => t.name;
String _buildCa(_Tenant t) => t.ca;
String _buildRegion(_Tenant t) => t.region;

@Preview(name: 'Normal', theme: scalarioDataTableThemes, wrapper: scalarioDataTableWrap)
Widget previewDataTableNormal() => ScalarioDataTable<_Tenant>(
      columns: _columns,
      rows: _mockTenants,
    );

@Preview(name: 'Sorted', theme: scalarioDataTableThemes, wrapper: scalarioDataTableWrap)
Widget previewDataTableSorted() => ScalarioDataTable<_Tenant>(
      columns: _columns,
      rows: _mockTenants,
      defaultSortKey: 'ca',
      defaultSortAsc: false,
    );

@Preview(name: 'Hover (web)', theme: scalarioDataTableThemes, wrapper: scalarioDataTableWrap)
Widget previewDataTableHover() => ScalarioDataTable<_Tenant>(
      columns: _columns,
      rows: _mockTenants,
      onRowTap: (_) {},
    );

@Preview(name: 'Loading', theme: scalarioDataTableThemes, wrapper: scalarioDataTableWrap)
Widget previewDataTableLoading() => ScalarioDataTable<_Tenant>.loading(columns: _columns);

@Preview(name: 'Empty', theme: scalarioDataTableThemes, wrapper: scalarioDataTableWrap)
Widget previewDataTableEmpty() => ScalarioDataTable<_Tenant>.empty(
      columns: _columns,
      message: 'Aucun tenant trouvé',
    );

class _DataTableShowcase extends StatelessWidget {
  const _DataTableShowcase();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(ScalarioSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Normal', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewDataTableNormal(),
            const SizedBox(height: ScalarioSpacing.space6),
            Text('Trié (CA décroissant)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewDataTableSorted(),
            const SizedBox(height: ScalarioSpacing.space6),
            Text('Loading', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewDataTableLoading(),
            const SizedBox(height: ScalarioSpacing.space6),
            Text('Empty', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ScalarioSpacing.space3),
            previewDataTableEmpty(),
          ],
        ),
      );
}

void main() => runApp(const ScalarioShowcaseApp(
      title: 'DataTable Showcase',
      child: _DataTableShowcase(),
    ));
