import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';
import '../_internal/shimmer.dart';

/// Alignement d'une colonne `DataColumnConfig`.
///
/// `right` impose Roboto Mono sur les cellules — utilisé pour les colonnes
/// numériques (montant, quantité). C'est la **seule** façon de marquer une
/// colonne comme numérique côté DataTable, par convention.
enum DataColumnAlign { left, center, right }

/// Configuration d'une colonne de `ScalarioDataTable`.
///
/// Le widget reste générique — c'est la `cellBuilder` qui sait comment
/// extraire la valeur de `T`.
class DataColumnConfig<T> {
  const DataColumnConfig({
    required this.key,
    required this.label,
    required this.cellBuilder,
    this.align = DataColumnAlign.left,
    this.sortable = true,
    this.comparator,
  });

  /// Clé stable pour le tri (`defaultSortKey`).
  final String key;

  /// Label d'en-tête (en français, Sprint 1).
  final String label;

  /// Comment rendre la cellule pour une ligne `T`.
  final String Function(T row) cellBuilder;

  final DataColumnAlign align;
  final bool sortable;

  /// Comparator custom (sinon : tri lexicographique sur `cellBuilder(row)`).
  final int Function(T a, T b)? comparator;
}

/// Table de données — utilisée principalement sur Web Admin.
///
/// **Spec source :** `design-process/D-Design-System/components/02-data-display.md`
/// (lignes 529-559). Le DS dit explicitement « exclusivement sur Flutter Web
/// (surfaces Admin). Non utilisé sur mobile. » Ce widget se rend correctement
/// sur mobile (scrollable horizontal) mais ce n'est pas son cas d'usage prévu.
///
/// **États supportés :** Normal, Tri actif, Hover (web), Loading, Vide, Erreur.
///
/// Implémenté sur le `DataTable` Material 3 — pas un grid custom — pour rester
/// cohérent avec le ThemeData Scalario.
class ScalarioDataTable<T> extends StatefulWidget {
  const ScalarioDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.defaultSortKey,
    this.defaultSortAsc = true,
  })  : _variant = _TableVariant.normal,
        _emptyMessage = null,
        _errorMessage = null,
        _onRetry = null;

  const ScalarioDataTable._empty({
    required this.columns,
    required String message,
  })  : rows = const <Never>[],
        onRowTap = null,
        defaultSortKey = null,
        defaultSortAsc = true,
        _variant = _TableVariant.empty,
        _emptyMessage = message,
        _errorMessage = null,
        _onRetry = null;

  const ScalarioDataTable._loading({required this.columns})
      : rows = const <Never>[],
        onRowTap = null,
        defaultSortKey = null,
        defaultSortAsc = true,
        _variant = _TableVariant.loading,
        _emptyMessage = null,
        _errorMessage = null,
        _onRetry = null;

  const ScalarioDataTable._error({
    required this.columns,
    required String message,
    VoidCallback? onRetry,
  })  : rows = const <Never>[],
        onRowTap = null,
        defaultSortKey = null,
        defaultSortAsc = true,
        _variant = _TableVariant.error,
        _emptyMessage = null,
        _errorMessage = message,
        _onRetry = onRetry;

  /// Construit un `ScalarioDataTable<Map<String, dynamic>>` depuis les props
  /// d'un `ComponentConfig` BDUI.
  ///
  /// Utilisé par le `ScalarioCanvasRegistry` (STORY-005) sous le type `DataTable`.
  ///
  /// Format props attendu :
  /// ```json
  /// {
  ///   "columns": [{ "key": "nom", "label": "Nom", "align": "left" }],
  ///   "rows": [{ "nom": "Riz 5kg" }]
  /// }
  /// ```
  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'DataTable',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    final props = config.props;
    final List<dynamic> rawCols = switch (props['columns']) {
      List<dynamic> l => l,
      _ => <dynamic>[],
    };
    final List<dynamic> rawRows = switch (props['rows']) {
      List<dynamic> l => l,
      _ => <dynamic>[],
    };

    final List<DataColumnConfig<Map<String, dynamic>>> columns =
        rawCols.map((dynamic c) {
      if (c is String) {
        return DataColumnConfig<Map<String, dynamic>>(
          key: c,
          label: c,
          cellBuilder: (Map<String, dynamic> row) =>
              row[c]?.toString() ?? '—',
          align: DataColumnAlign.left,
        );
      }
      final Map<String, dynamic> col = c as Map<String, dynamic>;
      final String key = col['key'] as String? ?? '';
      final String label = col['label'] as String? ?? key;
      final String alignStr = col['align'] as String? ?? 'left';
      final DataColumnAlign align = DataColumnAlign.values.firstWhere(
        (DataColumnAlign a) => a.name == alignStr,
        orElse: () => DataColumnAlign.left,
      );
      return DataColumnConfig<Map<String, dynamic>>(
        key: key,
        label: label,
        cellBuilder: (Map<String, dynamic> row) =>
            row[key]?.toString() ?? '—',
        align: align,
      );
    }).toList();

    if (columns.isEmpty) {
      return ScalarioDataTable<Map<String, dynamic>>.empty(
        columns: const <DataColumnConfig<Map<String, dynamic>>>[],
        message: 'Aucune colonne configurée',
      );
    }

    final List<Map<String, dynamic>> rows = rawRows
        .whereType<Map<String, dynamic>>()
        .toList();

    return ScalarioDataTable<Map<String, dynamic>>(
      columns: columns,
      rows: rows,
      defaultSortKey: props['default_sort_key'] as String?,
      defaultSortAsc: props['default_sort_asc'] as bool? ?? true,
    );
  }

  /// Variante "vide" — illustration `inbox` + message centré.
  factory ScalarioDataTable.empty({
    required List<DataColumnConfig<T>> columns,
    required String message,
  }) =>
      ScalarioDataTable<T>._empty(columns: columns, message: message);

  /// Variante "loading" — 5 lignes shimmer.
  factory ScalarioDataTable.loading({
    required List<DataColumnConfig<T>> columns,
  }) =>
      ScalarioDataTable<T>._loading(columns: columns);

  /// Variante "erreur" — icône + message + CTA "Réessayer".
  factory ScalarioDataTable.error({
    required List<DataColumnConfig<T>> columns,
    required String message,
    VoidCallback? onRetry,
  }) =>
      ScalarioDataTable<T>._error(
        columns: columns,
        message: message,
        onRetry: onRetry,
      );

  final List<DataColumnConfig<T>> columns;
  final List<T> rows;
  final ValueChanged<T>? onRowTap;
  final String? defaultSortKey;
  final bool defaultSortAsc;
  final _TableVariant _variant;
  final String? _emptyMessage;
  final String? _errorMessage;
  final VoidCallback? _onRetry;

  @override
  State<ScalarioDataTable<T>> createState() => _ScalarioDataTableState<T>();
}

class _ScalarioDataTableState<T> extends State<ScalarioDataTable<T>> {
  int? _sortColumnIndex;
  late bool _sortAsc;

  @override
  void initState() {
    super.initState();
    _sortAsc = widget.defaultSortAsc;
    if (widget.defaultSortKey != null) {
      final int idx = widget.columns
          .indexWhere((DataColumnConfig<T> c) => c.key == widget.defaultSortKey);
      if (idx != -1) _sortColumnIndex = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget._variant) {
      case _TableVariant.empty:
        return _EmptyState(message: widget._emptyMessage!);
      case _TableVariant.loading:
        return _LoadingState(columnCount: widget.columns.length);
      case _TableVariant.error:
        return _ErrorState(
          message: widget._errorMessage!,
          onRetry: widget._onRetry,
        );
      case _TableVariant.normal:
        return _buildTable(context);
    }
  }

  Widget _buildTable(BuildContext context) {
    final List<T> sorted = _sortedRows();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAsc,
              showCheckboxColumn: false,
              headingTextStyle: ScalarioTypography.captionMedium.copyWith(
                color: ScalarioColors.textSecondary,
              ),
              dataTextStyle: ScalarioTypography.body,
              dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Theme.of(context).colorScheme.surfaceContainerHighest;
                  }
                  return null;
                },
              ),
              columns: <DataColumn>[
                for (int i = 0; i < widget.columns.length; i++)
                  DataColumn(
                    label: Flexible(
                      child: Text(
                        widget.columns[i].label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    numeric: widget.columns[i].align == DataColumnAlign.right,
                    onSort: widget.columns[i].sortable
                        ? (int columnIndex, bool asc) {
                            setState(() {
                              _sortColumnIndex = columnIndex;
                              _sortAsc = asc;
                            });
                          }
                        : null,
                  ),
              ],
              rows: <DataRow>[
                for (final T row in sorted)
                  DataRow(
                    onSelectChanged: widget.onRowTap != null
                        ? (_) => widget.onRowTap!(row)
                        : null,
                    cells: <DataCell>[
                      for (final DataColumnConfig<T> col in widget.columns)
                        DataCell(
                          Align(
                            alignment: _alignmentFor(col.align),
                            child: Text(
                              col.cellBuilder(row),
                              style: col.align == DataColumnAlign.right
                                  ? ScalarioTypography.bodyMono
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<T> _sortedRows() {
    if (_sortColumnIndex == null) return widget.rows;
    final DataColumnConfig<T> col = widget.columns[_sortColumnIndex!];
    final List<({T row, int origin})> indexed = <({T row, int origin})>[
      for (int i = 0; i < widget.rows.length; i++)
        (row: widget.rows[i], origin: i),
    ];
    indexed.sort((({T row, int origin}) a, ({T row, int origin}) b) {
      final int cmp = col.comparator != null
          ? col.comparator!(a.row, b.row)
          : col.cellBuilder(a.row).compareTo(col.cellBuilder(b.row));
      if (cmp != 0) return _sortAsc ? cmp : -cmp;
      // Tri stable : préserver l'ordre d'origine pour les égalités.
      return a.origin.compareTo(b.origin);
    });
    return <T>[for (final ({T row, int origin}) e in indexed) e.row];
  }

  Alignment _alignmentFor(DataColumnAlign align) {
    switch (align) {
      case DataColumnAlign.left:
        return Alignment.centerLeft;
      case DataColumnAlign.center:
        return Alignment.center;
      case DataColumnAlign.right:
        return Alignment.centerRight;
    }
  }
}

enum _TableVariant { normal, empty, loading, error }

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ScalarioSpacing.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            ScalarioIcons.inbox,
            size: ScalarioIconSize.lg,
            color: ScalarioColors.textDisabled,
          ),
          const SizedBox(height: ScalarioSpacing.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ScalarioTypography.body.copyWith(
              color: ScalarioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.columnCount});

  final int columnCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ScalarioSpacing.space2,
            ),
            child: ScalarioShimmer(
              child: Row(
                children: <Widget>[
                  for (int c = 0; c < columnCount; c++) ...<Widget>[
                    const Expanded(
                      child: ScalarioShimmerBox(
                        width: double.infinity,
                        height: 14,
                      ),
                    ),
                    if (c < columnCount - 1)
                      const SizedBox(width: ScalarioSpacing.space3),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ScalarioSpacing.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            ScalarioIcons.error,
            size: ScalarioIconSize.lg,
            color: ScalarioColors.danger500,
          ),
          const SizedBox(height: ScalarioSpacing.space3),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ScalarioTypography.body.copyWith(
              color: ScalarioColors.danger700,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space3),
            TextButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}
