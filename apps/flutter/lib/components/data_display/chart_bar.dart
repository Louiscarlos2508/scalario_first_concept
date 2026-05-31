import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';
import '../../engine/canvas_registry/scalario_canvas_resolver.dart';
import '../_internal/shimmer.dart';

/// Point de donnée d'un `ChartBar` — un label, une valeur, une clé optionnelle.
///
/// La valeur est `double` pour permettre les fractions (ex: 12,5 kg).
class ChartDataPoint {
  const ChartDataPoint({
    required this.label,
    required this.value,
    this.key,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    final String? label = json['label'] as String?;
    final num? value = json['value'] as num?;
    if (label == null) {
      throw const FormatException("ChartDataPoint: 'label' requis");
    }
    if (value == null) {
      throw const FormatException("ChartDataPoint: 'value' (num) requis");
    }
    return ChartDataPoint(
      label: label,
      value: value.toDouble(),
      key: json['key'] as String?,
    );
  }

  final String label;
  final double value;
  final String? key;
}

/// Bar chart Scalario — première variante de `ChartWidget`.
///
/// **Spec source :** `design-process/D-Design-System/components/02-data-display.md`
/// (lignes 182-222). Note Sprint 1 : la spec parle de `ChartWidget` avec
/// `type: line | bar` ; on commence par la variante `bar` ici. La variante
/// `ChartLine` viendra dans une story ultérieure quand un écran l'exigera.
///
/// **Implémentation :** `fl_chart` (`BarChart` widget) — AC-36 STORY-003.
/// Couleurs depuis tokens : barres `primary-500`, hover `primary-700`,
/// axe X `neutral-300`, labels `caption` + `textSecondary`.
///
/// **États supportés :** Normal, Loading (5 barres shimmer), Vide (icône +
/// message), Erreur (icône + message + retry).
class ChartBar extends StatefulWidget {
  const ChartBar({
    super.key,
    this.title,
    required this.data,
    this.unit,
    this.period,
    this.onTap,
    this.height = 220,
  })  : _variant = _ChartVariant.normal,
        _errorMessage = null,
        _onRetry = null;

  const ChartBar._loading({this.title, this.height = 220})
      : data = const <ChartDataPoint>[],
        unit = null,
        period = null,
        onTap = null,
        _variant = _ChartVariant.loading,
        _errorMessage = null,
        _onRetry = null;

  const ChartBar._error({
    this.title,
    required String message,
    VoidCallback? onRetry,
    this.height = 220,
  })  : data = const <ChartDataPoint>[],
        unit = null,
        period = null,
        onTap = null,
        _variant = _ChartVariant.error,
        _errorMessage = message,
        _onRetry = onRetry;

  factory ChartBar.loading({String? title, double height = 220}) =>
      ChartBar._loading(title: title, height: height);

  factory ChartBar.error({
    String? title,
    required String message,
    VoidCallback? onRetry,
    double height = 220,
  }) =>
      ChartBar._error(
        title: title,
        message: message,
        onRetry: onRetry,
        height: height,
      );

  /// Construit un `ChartBar` depuis les props d'un `ComponentConfig` BDUI.
  ///
  /// Utilisé par le `ScalarioCanvasRegistry` (STORY-005). Délègue à [fromJson].
  static Widget fromConfig(ComponentConfig config, BuildContext ctx) {
    final variant = ScalarioCanvasResolver.resolveVariant(
      config.variant,
      component: 'ChartBar',
      screenWidth: MediaQuery.of(ctx).size.width,
    );
    try {
      if (variant == 'horizontal') {
        return _HorizontalChartBar(props: config.props);
      }
      if (variant == 'mini') {
        return _MiniChartBar(props: config.props);
      }
      return ChartBar.fromJson(config.props);
    } on FormatException {
      return ChartBar(
        data: const <ChartDataPoint>[],
        title: config.props['title'] as String?,
      );
    }
  }

  factory ChartBar.fromJson(Map<String, dynamic> json) {
    final String? title = json['title'] as String?;
    final List<dynamic>? rawData = switch (json['data']) {
      List<dynamic> l => l,
      _ => null,
    };
    final List<ChartDataPoint> data = rawData == null
        ? const <ChartDataPoint>[]
        : <ChartDataPoint>[
            for (final dynamic d in rawData)
              ChartDataPoint.fromJson(d as Map<String, dynamic>),
          ];
    return ChartBar(
      title: title,
      data: data,
      unit: json['unit'] as String?,
      period: json['period'] as String?,
    );
  }

  final String? title;
  final List<ChartDataPoint> data;
  final String? unit;
  final String? period;
  final ValueChanged<ChartDataPoint>? onTap;
  final double height;
  final _ChartVariant _variant;
  final String? _errorMessage;
  final VoidCallback? _onRetry;

  @override
  State<ChartBar> createState() => _ChartBarState();
}

class _ChartBarState extends State<ChartBar> {
  int? _hoveredIndex;

  String _formatValue(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.title != null && widget.title!.isNotEmpty) ...<Widget>[
          Text(widget.title!, style: ScalarioTypography.fontSectionTitle),
        ],
        if (widget.period != null) ...<Widget>[
          const SizedBox(height: ScalarioSpacing.space1),
          Text(widget.period!, style: ScalarioTypography.caption),
        ],
        const SizedBox(height: ScalarioSpacing.space3),
        SizedBox(
          height: widget.height,
          child: _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (widget._variant) {
      case _ChartVariant.loading:
        return _buildLoading();
      case _ChartVariant.error:
        return _buildError(context);
      case _ChartVariant.normal:
        if (widget.data.isEmpty) return _buildEmpty();
        return _buildChart(context);
    }
  }

  Widget _buildChart(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double totalWidth = constraints.maxWidth;
        final double slotWidth = totalWidth / widget.data.length;
        final double barWidth = (slotWidth * 0.6).clamp(8.0, 64.0);
        final double maxValue = widget.data.fold<double>(
          0,
          (double acc, ChartDataPoint p) => p.value > acc ? p.value : acc,
        );

        return MouseRegion(
          onHover: (PointerHoverEvent event) {
            final int idx = (event.localPosition.dx / slotWidth).floor();
            if (idx >= 0 && idx < widget.data.length && _hoveredIndex != idx) {
              setState(() => _hoveredIndex = idx);
            }
          },
          onExit: (_) {
            if (_hoveredIndex != null) setState(() => _hoveredIndex = null);
          },
          child: GestureDetector(
            key: const ValueKey<String>('chart-bar-tap-area'),
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.onTap == null
                ? null
                : (TapUpDetails details) {
                    final int idx =
                        (details.localPosition.dx / slotWidth).floor();
                    if (idx >= 0 && idx < widget.data.length) {
                      widget.onTap!(widget.data[idx]);
                    }
                  },
            child: BarChart(
              BarChartData(
                maxY: maxValue > 0 ? maxValue * 1.2 : 1,
                minY: 0,
                alignment: BarChartAlignment.spaceEvenly,
                barGroups: <BarChartGroupData>[
                  for (int i = 0; i < widget.data.length; i++)
                    BarChartGroupData(
                      x: i,
                      showingTooltipIndicators:
                          _hoveredIndex == i ? <int>[0] : <int>[],
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: widget.data[i].value,
                          width: barWidth,
                          color: _hoveredIndex == i
                              ? ScalarioColors.primary700
                              : ScalarioColors.primary500,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(ScalarioRadius.sm),
                          ),
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: ScalarioSpacing.space6,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final int idx = value.round();
                        if (idx < 0 || idx >= widget.data.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          widget.data[idx].label,
                          style: ScalarioTypography.caption.copyWith(
                            color: ScalarioColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                gridData: const FlGridData(),
                borderData: FlBorderData(
                  border: const Border(
                    bottom: BorderSide(color: ScalarioColors.neutral300),
                  ),
                ),
                barTouchData: BarTouchData(
                  // Touch events handled by outer GestureDetector + MouseRegion.
                  // handleBuiltInTouches: false lets showingTooltipIndicators
                  // drive tooltip display manually on hover.
                  enabled: false,
                  handleBuiltInTouches: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => ScalarioColors.neutral900,
                    getTooltipItem: (
                      BarChartGroupData group,
                      int groupIndex,
                      BarChartRodData rod,
                      int rodIndex,
                    ) {
                      if (groupIndex < 0 ||
                          groupIndex >= widget.data.length) {
                        return null;
                      }
                      final ChartDataPoint p = widget.data[groupIndex];
                      final String label = widget.unit != null
                          ? '${_formatValue(p.value)} ${widget.unit}'
                          : _formatValue(p.value);
                      return BarTooltipItem(
                        label,
                        ScalarioTypography.captionMono.copyWith(
                          color: ScalarioColors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              swapAnimationDuration: Duration.zero,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final math.Random rng = math.Random(42);
        const int barCount = 5;
        final double slotWidth = constraints.maxWidth / barCount;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < barCount; i++)
              SizedBox(
                width: slotWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ScalarioSpacing.space2,
                  ),
                  child: ScalarioShimmer(
                    child: ScalarioShimmerBox(
                      width: double.infinity,
                      height: constraints.maxHeight *
                          (0.4 + rng.nextDouble() * 0.6),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            ScalarioIcons.chart,
            size: ScalarioIconSize.lg,
            color: ScalarioColors.textDisabled,
          ),
          const SizedBox(height: ScalarioSpacing.space3),
          Text(
            'Pas de données pour cette période',
            textAlign: TextAlign.center,
            style: ScalarioTypography.body.copyWith(
              color: ScalarioColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
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
            widget._errorMessage ?? 'Erreur de chargement du graphique',
            textAlign: TextAlign.center,
            style: ScalarioTypography.body.copyWith(
              color: ScalarioColors.danger700,
            ),
          ),
          if (widget._onRetry != null) ...<Widget>[
            const SizedBox(height: ScalarioSpacing.space3),
            TextButton(
              onPressed: widget._onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ChartVariant { normal, loading, error }

// --- Variant stubs (V14-003) ---

class _HorizontalChartBar extends StatelessWidget {
  const _HorizontalChartBar({required this.props});
  final Map<String, dynamic> props;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space4),
      child: Center(
        child: Text('HorizontalChart',
          style: ScalarioTypography.caption.copyWith(color: ScalarioColors.textDisabled)),
      ),
    );
  }
}

class _MiniChartBar extends StatelessWidget {
  const _MiniChartBar({required this.props});
  final Map<String, dynamic> props;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text('MiniChart',
          style: ScalarioTypography.caption.copyWith(color: ScalarioColors.textDisabled)),
      ),
    );
  }
}
