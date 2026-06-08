// ============================================================
// sca_filter_builder.dart - REFONTE COMPLÈTE (Phase 7)
// Système de filtres interactif avec Popover, opérateurs logiques
// Inspiré du RecordFilterGroupsMenu de Twenty
// ============================================================
import 'package:flutter/material.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../theme/sca_tokens.dart';
import '../_internal/sca_focus_wrapper.dart';

// ---- Types ----

enum ScaFilterOperator {
  equals,
  notEquals,
  contains,
  notContains,
  isEmpty,
  isNotEmpty,
  greaterThan,
  lessThan,
}

class ScaFilter {
  final String fieldKey;
  final String fieldLabel;
  final ScaFilterOperator operator;
  final String value;

  const ScaFilter({
    required this.fieldKey,
    required this.fieldLabel,
    required this.operator,
    required this.value,
  });
}

// ---- Main Widget ----

class ScaFilterBuilder extends StatefulWidget {
  final ComponentConfig config;

  const ScaFilterBuilder({super.key, required this.config});

  @override
  State<ScaFilterBuilder> createState() => _ScaFilterBuilderState();
}

class _ScaFilterBuilderState extends State<ScaFilterBuilder> {
  final List<ScaFilter> _activeFilters = [];

  String _operatorLabel(ScaFilterOperator op) {
    switch (op) {
      case ScaFilterOperator.equals:
        return 'est';
      case ScaFilterOperator.notEquals:
        return "n'est pas";
      case ScaFilterOperator.contains:
        return 'contient';
      case ScaFilterOperator.notContains:
        return 'ne contient pas';
      case ScaFilterOperator.isEmpty:
        return 'est vide';
      case ScaFilterOperator.isNotEmpty:
        return "n'est pas vide";
      case ScaFilterOperator.greaterThan:
        return 'est supérieur à';
      case ScaFilterOperator.lessThan:
        return 'est inférieur à';
    }
  }

  void _removeFilter(int index) {
    setState(() => _activeFilters.removeAt(index));
  }

  void _showAddFilterPopover(BuildContext context) {
    final fields = (widget.config.props['fields'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [
          {'key': 'name', 'label': 'Nom'},
          {'key': 'status', 'label': 'Statut'},
          {'key': 'amount', 'label': 'Montant'},
          {'key': 'date', 'label': 'Date'},
        ];

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => _FilterPopover(
        fields: fields,
        onAdd: (filter) {
          setState(() => _activeFilters.add(filter));
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Active filter chips
        for (int i = 0; i < _activeFilters.length; i++)
          _ActiveFilterChip(
            filter: _activeFilters[i],
            operatorLabel: _operatorLabel(_activeFilters[i].operator),
            onRemove: () => _removeFilter(i),
          ),

        // Add filter button
        ScaFocusWrapper(
          onTap: () => _showAddFilterPopover(context),
          padding: const EdgeInsets.symmetric(
            horizontal: ScaSpacing.s2,
            vertical: ScaSpacing.s1,
          ),
          borderRadius: BorderRadius.circular(ScaRadius.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_outlined,
                size: 16,
                color: _activeFilters.isEmpty
                    ? ScaColors.fontSecondary
                    : ScaColors.focusRing,
              ),
              const SizedBox(width: ScaSpacing.s1),
              Text(
                _activeFilters.isEmpty
                    ? 'Filtrer'
                    : '${_activeFilters.length} filtre${_activeFilters.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _activeFilters.isEmpty
                      ? ScaColors.fontSecondary
                      : ScaColors.focusRing,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: _activeFilters.isEmpty
                    ? ScaColors.fontSecondary
                    : ScaColors.focusRing,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---- Active Filter Chip ----

class _ActiveFilterChip extends StatelessWidget {
  final ScaFilter filter;
  final String operatorLabel;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.filter,
    required this.operatorLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: ScaSpacing.s1),
      padding: const EdgeInsets.symmetric(
        horizontal: ScaSpacing.s2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: ScaColors.infoBg,
        border: Border.all(color: ScaColors.focusRing.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(ScaRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${filter.fieldLabel} $operatorLabel ${filter.value}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ScaColors.infoFg,
            ),
          ),
          const SizedBox(width: 4),
          ScaFocusWrapper(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(ScaRadius.full),
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: ScaColors.infoFg,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Filter Popover Dialog ----

class _FilterPopover extends StatefulWidget {
  final List<Map<String, dynamic>> fields;
  final void Function(ScaFilter) onAdd;

  const _FilterPopover({required this.fields, required this.onAdd});

  @override
  State<_FilterPopover> createState() => _FilterPopoverState();
}

class _FilterPopoverState extends State<_FilterPopover> {
  Map<String, dynamic>? _selectedField;
  ScaFilterOperator _selectedOperator = ScaFilterOperator.contains;
  final _valueController = TextEditingController();

  final _operators = [
    ScaFilterOperator.equals,
    ScaFilterOperator.notEquals,
    ScaFilterOperator.contains,
    ScaFilterOperator.notContains,
    ScaFilterOperator.isEmpty,
    ScaFilterOperator.isNotEmpty,
  ];

  String _operatorLabel(ScaFilterOperator op) {
    const labels = {
      ScaFilterOperator.equals: 'est',
      ScaFilterOperator.notEquals: "n'est pas",
      ScaFilterOperator.contains: 'contient',
      ScaFilterOperator.notContains: 'ne contient pas',
      ScaFilterOperator.isEmpty: 'est vide',
      ScaFilterOperator.isNotEmpty: "n'est pas vide",
      ScaFilterOperator.greaterThan: 'est supérieur à',
      ScaFilterOperator.lessThan: 'est inférieur à',
    };
    return labels[op] ?? op.name;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 300,
          margin: const EdgeInsets.only(top: 80),
          decoration: BoxDecoration(
            color: ScaColors.bgPrimary,
            borderRadius: BorderRadius.circular(ScaRadius.lg),
            boxShadow: ScaShadows.superHeavy,
            border: Border.all(color: ScaColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ScaSpacing.s4,
                  ScaSpacing.s3,
                  ScaSpacing.s4,
                  ScaSpacing.s2,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Ajouter un filtre',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ScaColors.fontPrimary,
                      ),
                    ),
                    const Spacer(),
                    ScaFocusWrapper(
                      onTap: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.all(4),
                      borderRadius: BorderRadius.circular(ScaRadius.sm),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: ScaColors.fontTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: ScaColors.borderLight),

              Padding(
                padding: const EdgeInsets.all(ScaSpacing.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field selector
                    const _PopoverLabel(text: 'Champ'),
                    _DropdownField<Map<String, dynamic>>(
                      value: _selectedField,
                      items: widget.fields,
                      itemLabel: (f) => f['label'] as String,
                      hint: 'Sélectionner un champ...',
                      onChanged: (v) => setState(() => _selectedField = v),
                    ),
                    const SizedBox(height: ScaSpacing.s2),

                    // Operator selector
                    const _PopoverLabel(text: 'Condition'),
                    _DropdownField<ScaFilterOperator>(
                      value: _selectedOperator,
                      items: _operators,
                      itemLabel: _operatorLabel,
                      hint: 'Condition',
                      onChanged: (v) => setState(() => _selectedOperator = v!),
                    ),
                    const SizedBox(height: ScaSpacing.s2),

                    // Value input (hidden for isEmpty/isNotEmpty)
                    if (_selectedOperator != ScaFilterOperator.isEmpty &&
                        _selectedOperator != ScaFilterOperator.isNotEmpty) ...[
                      const _PopoverLabel(text: 'Valeur'),
                      TextField(
                        controller: _valueController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ScaColors.fontPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Entrer une valeur...',
                          hintStyle: const TextStyle(
                            color: ScaColors.fontLight,
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: ScaSpacing.s2,
                            vertical: ScaSpacing.s1,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ScaRadius.sm),
                            borderSide: const BorderSide(
                                color: ScaColors.borderMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ScaRadius.sm),
                            borderSide: const BorderSide(
                              color: ScaColors.focusRing,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(ScaRadius.sm),
                            borderSide: const BorderSide(
                                color: ScaColors.borderLight),
                          ),
                        ),
                      ),
                      const SizedBox(height: ScaSpacing.s3),
                    ] else
                      const SizedBox(height: ScaSpacing.s3),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ScaFocusWrapper(
                        onTap: () {
                          if (_selectedField == null) return;
                          widget.onAdd(ScaFilter(
                            fieldKey: _selectedField!['key'] as String,
                            fieldLabel: _selectedField!['label'] as String,
                            operator: _selectedOperator,
                            value: _valueController.text,
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: ScaSpacing.s2,
                          ),
                          decoration: BoxDecoration(
                            color: ScaColors.focusRing,
                            borderRadius:
                                BorderRadius.circular(ScaRadius.sm),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Appliquer le filtre',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopoverLabel extends StatelessWidget {
  final String text;

  const _PopoverLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ScaColors.fontTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final String hint;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint,
          style: const TextStyle(
              color: ScaColors.fontLight, fontSize: 13)),
      style: const TextStyle(
          color: ScaColors.fontPrimary, fontSize: 13),
      dropdownColor: ScaColors.bgPrimary,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ScaSpacing.s2,
          vertical: ScaSpacing.s1,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScaRadius.sm),
          borderSide: const BorderSide(color: ScaColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScaRadius.sm),
          borderSide: const BorderSide(color: ScaColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ScaRadius.sm),
          borderSide:
              const BorderSide(color: ScaColors.focusRing, width: 1.5),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
