import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../core/theme/theme_extensions.dart';
import '../_internal/shimmer.dart';

/// Statut sémantique d'un `KPICard`.
///
/// - `nominal` : KPI dans la zone OK — fond surface neutre, valeur primary.
/// - `warning` : KPI à surveiller — fond `warning-100`, bordure et valeur `warning-700`.
/// - `critical` : KPI en alerte — fond `danger-100`, bordure et valeur `danger-500`.
enum KpiStatus { nominal, warning, critical }

/// Carte de KPI métier — composant data-display le plus utilisé.
///
/// **Rôle :** affiche une métrique calculée (CA, marge, transactions, stock)
/// avec sa valeur en Roboto Mono (anti-layout-shift), son label et sa variation.
///
/// **Spec source :** `design-process/D-Design-System/components/02-data-display.md`
/// (lignes 14-69).
///
/// **États supportés :** `nominal`, `warning`, `critical`, tappable, loading,
/// empty, error.
///
/// **i18n (Phase 1) :** les strings d'erreur/empty sont en français — STORY-042
/// les wrappera dans `AppLocalizations`.
///
/// Usage BDUI :
/// ```dart
/// KPICard.fromJson({
///   'label': 'CA du jour',
///   'value': '47 500',
///   'unit': 'FCFA',
///   'delta': '+12% vs hier',
///   'delta_positive': true,
///   'status': 'nominal',
/// });
/// ```
class KPICard extends StatelessWidget {
  const KPICard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.delta,
    this.deltaPositive = true,
    this.status = KpiStatus.nominal,
    this.onTap,
  })  : _variant = _KpiVariant.normal,
        _errorMessage = null;

  const KPICard._loading({required this.label})
      : value = '',
        unit = null,
        delta = null,
        deltaPositive = true,
        status = KpiStatus.nominal,
        onTap = null,
        _variant = _KpiVariant.loading,
        _errorMessage = null;

  const KPICard._empty({required this.label})
      : value = '—',
        unit = null,
        delta = null,
        deltaPositive = true,
        status = KpiStatus.nominal,
        onTap = null,
        _variant = _KpiVariant.empty,
        _errorMessage = null;

  const KPICard._error({required this.label, String? message})
      : value = '',
        unit = null,
        delta = null,
        deltaPositive = true,
        status = KpiStatus.critical,
        onTap = null,
        _variant = _KpiVariant.error,
        _errorMessage = message;

  /// Skeleton shimmer pendant que la donnée charge — label visible mais grisé.
  factory KPICard.loading({required String label}) =>
      KPICard._loading(label: label);

  /// Pas de donnée disponible — valeur "—" sur fond neutre.
  factory KPICard.empty(String label) => KPICard._empty(label: label);

  /// Erreur de chargement — icône + message court (truncated 2 lignes).
  factory KPICard.error({required String label, String? message}) =>
      KPICard._error(label: label, message: message);

  /// Construit un `KPICard` depuis les props d'un `ComponentConfig` BDUI.
  ///
  /// Utilisé par le `ComponentRegistry` (STORY-005). Délègue à [fromJson].
  static Widget fromConfig(Map<String, dynamic> props, BuildContext ctx) {
    try {
      return KPICard.fromJson(props);
    } on FormatException {
      return KPICard.error(label: props['label'] as String? ?? 'KPI');
    }
  }

  /// Construit un `KPICard` depuis un `Map<String, dynamic>` BDUI.
  ///
  /// Throws `FormatException` si `label` ou `value` manquent — le moteur BDUI
  /// (STORY-005) catche ces exceptions pour afficher un fallback Error Boundary.
  factory KPICard.fromJson(Map<String, dynamic> json) {
    final String? label = json['label'] as String?;
    final String? value = json['value'] as String?;
    if (label == null) {
      throw const FormatException("KPICard: 'label' requis");
    }
    if (value == null) {
      throw const FormatException("KPICard: 'value' requis");
    }
    return KPICard(
      label: label,
      value: value,
      unit: json['unit'] as String?,
      delta: json['delta'] as String?,
      deltaPositive: json['delta_positive'] as bool? ?? true,
      status: _parseStatus(json['status'] as String?),
    );
  }

  static KpiStatus _parseStatus(String? raw) {
    if (raw == null) return KpiStatus.nominal;
    return KpiStatus.values.firstWhere(
      (KpiStatus s) => s.name == raw,
      orElse: () => KpiStatus.nominal,
    );
  }

  final String label;
  final String value;
  final String? unit;
  final String? delta;
  final bool deltaPositive;
  final KpiStatus status;
  final VoidCallback? onTap;
  final _KpiVariant _variant;
  final String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    switch (_variant) {
      case _KpiVariant.loading:
        return _buildLoading();
      case _KpiVariant.empty:
        return _buildEmpty();
      case _KpiVariant.error:
        return _buildError();
      case _KpiVariant.normal:
        return _buildNormal(context);
    }
  }

  Widget _buildNormal(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ScalarioColorsExtension ext =
        theme.extension<ScalarioColorsExtension>()!;
    final _KpiPalette palette = _paletteFor(status, ext, theme.colorScheme);

    final Widget card = Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: palette.borderLeft != null
            ? Border(
                left: BorderSide(color: palette.borderLeft!, width: 3),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: ScalarioTypography.fontKpiLabel),
          const SizedBox(height: ScalarioSpacing.space2),
          Text(
            value,
            style: ScalarioTypography.fontKpiValue.copyWith(
              color: palette.value,
            ),
          ),
          if (unit != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space1),
            Text(unit!, style: ScalarioTypography.caption),
          ],
          if (delta != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space1),
            Text(
              delta!,
              style: ScalarioTypography.fontKpiDelta.copyWith(
                color: deltaPositive ? ext.synced : ScalarioColors.danger500,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ScalarioRadius.md),
      child: Stack(
        children: <Widget>[
          card,
          const Positioned(
            right: ScalarioSpacing.space3,
            bottom: ScalarioSpacing.space3,
            child: Icon(
              ScalarioIcons.chevronRight,
              size: ScalarioIconSize.xs,
              color: ScalarioColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      decoration: BoxDecoration(
        color: ScalarioColors.bgCard,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: ScalarioTypography.fontKpiLabel.copyWith(
              color: ScalarioColors.textDisabled,
            ),
          ),
          const SizedBox(height: ScalarioSpacing.space2),
          const ScalarioShimmer(
            child: ScalarioShimmerBox(width: 120, height: 32),
          ),
          const SizedBox(height: ScalarioSpacing.space2),
          const ScalarioShimmer(
            child: ScalarioShimmerBox(width: 80, height: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      decoration: BoxDecoration(
        color: ScalarioColors.neutral50,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: ScalarioTypography.fontKpiLabel.copyWith(
              color: ScalarioColors.textDisabled,
            ),
          ),
          const SizedBox(height: ScalarioSpacing.space2),
          Text(
            value,
            style: ScalarioTypography.fontKpiValue.copyWith(
              color: ScalarioColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      decoration: BoxDecoration(
        color: ScalarioColors.danger100,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: const Border(
          left: BorderSide(color: ScalarioColors.danger500, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                ScalarioIcons.error,
                size: ScalarioIconSize.sm,
                color: ScalarioColors.danger500,
              ),
              const SizedBox(width: ScalarioSpacing.space2),
              Expanded(
                child: Text(
                  label,
                  style: ScalarioTypography.fontKpiLabel.copyWith(
                    color: ScalarioColors.danger700,
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space2),
            Text(
              _errorMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ScalarioTypography.caption.copyWith(
                color: ScalarioColors.danger700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _KpiPalette _paletteFor(
    KpiStatus status,
    ScalarioColorsExtension ext,
    ColorScheme scheme,
  ) {
    switch (status) {
      case KpiStatus.nominal:
        return _KpiPalette(
          background: scheme.surface,
          value: scheme.onSurface,
          borderLeft: null,
        );
      case KpiStatus.warning:
        return const _KpiPalette(
          background: ScalarioColors.warning100,
          value: ScalarioColors.warning700,
          borderLeft: ScalarioColors.warning500,
        );
      case KpiStatus.critical:
        return const _KpiPalette(
          background: ScalarioColors.danger100,
          value: ScalarioColors.danger500,
          borderLeft: ScalarioColors.danger500,
        );
    }
  }
}

enum _KpiVariant { normal, loading, empty, error }

class _KpiPalette {
  const _KpiPalette({
    required this.background,
    required this.value,
    required this.borderLeft,
  });

  final Color background;
  final Color value;
  final Color? borderLeft;
}
