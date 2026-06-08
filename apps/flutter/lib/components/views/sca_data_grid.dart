// ============================================================
// sca_data_grid.dart - REFONTE COMPLÈTE (Phase 7)
// DataGrid universelle avec hover states, sélection checkbox,
// menu contextuel "...", tri de colonnes
// Inspiré de RecordTable de Twenty
// ============================================================
import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../theme/sca_tokens.dart';
import '../_internal/sca_focus_wrapper.dart';

class ScaDataGrid extends StatefulWidget {
  final ComponentConfig config;

  const ScaDataGrid({super.key, required this.config});

  @override
  State<ScaDataGrid> createState() => _ScaDataGridState();
}

class _ScaDataGridState extends State<ScaDataGrid> {
  final Set<int> _selectedRows = {};
  int? _hoveredRow;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int? _contextMenuRow;

  List<Map<String, dynamic>> get _columns {
    return ((widget.config.props['columns'] as List<dynamic>?) ?? [])
        .map((c) => c as Map<String, dynamic>)
        .toList();
  }

  List<Map<String, dynamic>> get _rows {
    return ((widget.config.props['rows'] as List<dynamic>?) ?? [])
        .map((r) => r as Map<String, dynamic>)
        .toList();
  }

  bool get _allSelected =>
      _rows.isNotEmpty && _selectedRows.length == _rows.length;

  void _toggleSelectAll() {
    setState(() {
      if (_allSelected) {
        _selectedRows.clear();
      } else {
        _selectedRows.addAll(List.generate(_rows.length, (i) => i));
      }
    });
  }

  void _toggleRow(int index) {
    setState(() {
      if (_selectedRows.contains(index)) {
        _selectedRows.remove(index);
      } else {
        _selectedRows.add(index);
      }
    });
  }

  void _showContextMenu(BuildContext context, int rowIndex, Offset position) {
    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ScaRadius.md),
        side: const BorderSide(color: ScaColors.borderLight),
      ),
      color: ScaColors.bgPrimary,
      elevation: 0,
      items: <PopupMenuEntry<void>>[
        PopupMenuItem<void>(
          child: _ContextMenuItem(
              icon: Icons.open_in_new_rounded, label: 'Ouvrir'),
          onTap: () {},
        ),
        PopupMenuItem<void>(
          child: _ContextMenuItem(
              icon: Icons.edit_rounded, label: 'Modifier'),
          onTap: () {},
        ),
        PopupMenuItem<void>(
          child: _ContextMenuItem(
              icon: Icons.content_copy_rounded, label: 'Dupliquer'),
          onTap: () {},
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<void>(
          child: _ContextMenuItem(
            icon: Icons.delete_rounded,
            label: 'Supprimer',
            isDestructive: true,
          ),
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    final rows = _rows;

    return Container(
      decoration: BoxDecoration(
        color: ScaColors.bgPrimary,
        border: Border.all(color: ScaColors.borderLight),
        borderRadius: BorderRadius.circular(ScaRadius.lg),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---- Header Row ----
          _DataGridHeader(
            columns: columns,
            allSelected: _allSelected,
            selectedCount: _selectedRows.length,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            onSelectAll: _toggleSelectAll,
            onSort: (colIndex, asc) {
              setState(() {
                _sortColumnIndex = colIndex;
                _sortAscending = asc;
              });
            },
          ),
          // ---- Data Rows ----
          Expanded(
            child: rows.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedRows.contains(index);
                      final isHovered = _hoveredRow == index;

                      return _DataGridRow(
                        columns: columns,
                        rowData: rows[index],
                        isSelected: isSelected,
                        isHovered: isHovered,
                        isEven: index.isEven,
                        onHover: (h) =>
                            setState(() => _hoveredRow = h ? index : null),
                        onSelect: () => _toggleRow(index),
                        onContextMenu: (position) =>
                            _showContextMenu(context, index, position),
                      );
                    },
                  ),
          ),
          // ---- Footer (count) ----
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ScaSpacing.s4,
              vertical: ScaSpacing.s2,
            ),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: ScaColors.borderLight)),
              color: ScaColors.bgSecondary,
            ),
            child: Text(
              _selectedRows.isEmpty
                  ? '${rows.length} enregistrement${rows.length > 1 ? 's' : ''}'
                  : '${_selectedRows.length} sélectionné${_selectedRows.length > 1 ? 's' : ''} sur ${rows.length}',
              style: const TextStyle(
                fontSize: 12,
                color: ScaColors.fontTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Header ----

class _DataGridHeader extends StatelessWidget {
  final List<Map<String, dynamic>> columns;
  final bool allSelected;
  final int selectedCount;
  final int? sortColumnIndex;
  final bool sortAscending;
  final VoidCallback onSelectAll;
  final void Function(int, bool) onSort;

  const _DataGridHeader({
    required this.columns,
    required this.allSelected,
    required this.selectedCount,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSelectAll,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: ScaColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: ScaSpacing.s2),
      child: Row(
        children: [
          // Checkbox header
          SizedBox(
            width: 40,
            child: Checkbox(
              value: allSelected,
              tristate: selectedCount > 0 && !allSelected,
              onChanged: (_) => onSelectAll(),
              activeColor: ScaColors.focusRing,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ScaRadius.xs),
              ),
              side: const BorderSide(color: ScaColors.borderStrong, width: 1.5),
            ),
          ),
          // Column headers
          for (int i = 0; i < columns.length; i++)
            Expanded(
              flex: (columns[i]['flex'] as num?)?.toInt() ?? 1,
              child: ScaFocusWrapper(
                onTap: () => onSort(i, sortColumnIndex == i ? !sortAscending : true),
                padding: const EdgeInsets.symmetric(
                  horizontal: ScaSpacing.s2,
                  vertical: ScaSpacing.s1,
                ),
                child: Row(
                  children: [
                    Text(
                      columns[i]['label'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ScaColors.fontTertiary,
                      ),
                    ),
                    if (sortColumnIndex == i)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Icon(
                          sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: ScaColors.focusRing,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          // Space for context menu button
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ---- Data Row ----

class _DataGridRow extends StatelessWidget {
  final List<Map<String, dynamic>> columns;
  final Map<String, dynamic> rowData;
  final bool isSelected;
  final bool isHovered;
  final bool isEven;
  final void Function(bool) onHover;
  final VoidCallback onSelect;
  final void Function(Offset) onContextMenu;

  const _DataGridRow({
    required this.columns,
    required this.rowData,
    required this.isSelected,
    required this.isHovered,
    required this.isEven,
    required this.onHover,
    required this.onSelect,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: ScaAnimation.fast,
        height: 40,
        color: isSelected
            ? ScaColors.infoBg
            : isHovered
                ? ScaColors.transparentLight
                : Colors.transparent,
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: ScaSpacing.s2),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelect(),
                  activeColor: ScaColors.focusRing,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ScaRadius.xs),
                  ),
                  side: const BorderSide(
                      color: ScaColors.borderStrong, width: 1.5),
                ),
              ),
            ),
            // Cell values
            for (final col in columns)
              Expanded(
                flex: (col['flex'] as num?)?.toInt() ?? 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ScaSpacing.s2,
                  ),
                  child: _CellRenderer(
                    value: rowData[col['key'] as String? ?? ''],
                    type: col['type'] as String? ?? 'text',
                  ),
                ),
              ),
            // Context menu button "..."
            AnimatedOpacity(
              duration: ScaAnimation.fast,
              opacity: isHovered || isSelected ? 1.0 : 0.0,
              child: SizedBox(
                width: 40,
                child: ScaFocusWrapper(
                  onTap: () {
                    final renderBox = context.findRenderObject() as RenderBox?;
                    final position =
                        renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
                    onContextMenu(position + const Offset(0, 40));
                  },
                  padding: const EdgeInsets.all(ScaSpacing.s1),
                  borderRadius: BorderRadius.circular(ScaRadius.sm),
                  child: const Icon(
                    Icons.more_horiz_rounded,
                    size: 16,
                    color: ScaColors.fontSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Cell Renderer ----

class _CellRenderer extends StatelessWidget {
  final dynamic value;
  final String type;

  const _CellRenderer({required this.value, required this.type});

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const Text(
        '—',
        style: TextStyle(color: ScaColors.fontLight, fontSize: 13),
      );
    }

    switch (type) {
      case 'badge':
      case 'status':
        return _StatusBadge(label: value.toString());
      case 'number':
        return Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            color: ScaColors.fontPrimary,
          ),
        );
      default:
        return Text(
          value.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: ScaColors.fontPrimary,
          ),
        );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  static const _statusColors = {
    'actif': (bg: Color(0xFFEDF7EE), fg: Color(0xFF1F7A32)),
    'inactif': (bg: Color(0xFFF3F3F3), fg: Color(0xFF4A4A4A)),
    'en_attente': (bg: Color(0xFFFFF8E1), fg: Color(0xFF8B5E00)),
    'erreur': (bg: Color(0xFFFEECEB), fg: Color(0xFFB71C1C)),
  };

  @override
  Widget build(BuildContext context) {
    final key = label.toLowerCase().replaceAll(' ', '_');
    final colors = _statusColors[key] ??
        (bg: ScaColors.neutralBg, fg: ScaColors.fontSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(ScaRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colors.fg,
        ),
      ),
    );
  }
}

// ---- Context Menu Item ----

class _ContextMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? ScaColors.dangerFg : ScaColors.fontSecondary;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: ScaSpacing.s2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---- Empty State ----

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: ScaColors.fontLight),
          SizedBox(height: ScaSpacing.s2),
          Text(
            'Aucun enregistrement',
            style: TextStyle(color: ScaColors.fontTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
