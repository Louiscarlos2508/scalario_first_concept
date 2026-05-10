import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
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
/// **Implémentation :** `CustomPaint` direct, pas de dépendance externe
/// (`fl_chart`). Le besoin Sprint 1 est minimal — un bar chart de base avec
/// axes, labels et hover. Si on a besoin de plus (tooltips, animations,
/// stacks), on évaluera à ce moment-là d'introduire `fl_chart`.
///
/// **États supportés :** Normal, Loading (5 barres shimmer), Vide (icône +
/// message), Erreur (icône + message + retry).
class ChartBar extends StatefulWidget {
  const ChartBar({
    super.key,
    required this.title,
    required this.data,
    this.unit,
    this.period,
    this.onTap,
    this.height = 220,
  })  : _variant = _ChartVariant.normal,
        _errorMessage = null,
        _onRetry = null;

  const ChartBar._loading({required this.title, this.height = 220})
      : data = const <ChartDataPoint>[],
        unit = null,
        period = null,
        onTap = null,
        _variant = _ChartVariant.loading,
        _errorMessage = null,
        _onRetry = null;

  const ChartBar._error({
    required this.title,
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

  factory ChartBar.loading({required String title, double height = 220}) =>
      ChartBar._loading(title: title, height: height);

  factory ChartBar.error({
    required String title,
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

  factory ChartBar.fromJson(Map<String, dynamic> json) {
    final String? title = json['title'] as String?;
    if (title == null) {
      throw const FormatException("ChartBar: 'title' requis");
    }
    final List<dynamic>? rawData = json['data'] as List<dynamic>?;
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

  final String title;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(widget.title, style: ScalarioTypography.fontSectionTitle),
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
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        final double barCount = widget.data.length.toDouble();
        final double slotWidth = width / barCount;

        return MouseRegion(
          onHover: (PointerHoverEvent event) {
            final int idx = (event.localPosition.dx / slotWidth).floor();
            if (idx >= 0 && idx < widget.data.length) {
              if (_hoveredIndex != idx) {
                setState(() => _hoveredIndex = idx);
              }
            }
          },
          onExit: (_) {
            if (_hoveredIndex != null) {
              setState(() => _hoveredIndex = null);
            }
          },
          child: GestureDetector(
            key: const ValueKey<String>('chart-bar-tap-area'),
            onTapUp: widget.onTap == null
                ? null
                : (TapUpDetails details) {
                    final int idx =
                        (details.localPosition.dx / slotWidth).floor();
                    if (idx >= 0 && idx < widget.data.length) {
                      widget.onTap!(widget.data[idx]);
                    }
                  },
            child: CustomPaint(
              size: Size(width, height),
              painter: _BarChartPainter(
                data: widget.data,
                hoveredIndex: _hoveredIndex,
                axisLabelStyle: ScalarioTypography.caption,
                valueLabelStyle: ScalarioTypography.captionMono,
                unit: widget.unit,
              ),
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
        const double barInset = ScalarioSpacing.space2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (int i = 0; i < barCount; i++)
              SizedBox(
                width: slotWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: barInset),
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

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.data,
    required this.hoveredIndex,
    required this.axisLabelStyle,
    required this.valueLabelStyle,
    this.unit,
  });

  final List<ChartDataPoint> data;
  final int? hoveredIndex;
  final TextStyle axisLabelStyle;
  final TextStyle valueLabelStyle;
  final String? unit;

  static const double _axisInset = 32;
  static const double _topPadding = 16;
  static const double _barInset = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxValue = data.fold<double>(
      0,
      (double acc, ChartDataPoint p) => p.value > acc ? p.value : acc,
    );
    if (maxValue <= 0) return;

    final double chartHeight = size.height - _axisInset - _topPadding;
    final double chartWidth = size.width;
    final double slotWidth = chartWidth / data.length;

    final Paint axisPaint = Paint()
      ..color = ScalarioColors.neutral300
      ..strokeWidth = 1;

    // Axe horizontal (baseline).
    canvas.drawLine(
      Offset(0, _topPadding + chartHeight),
      Offset(chartWidth, _topPadding + chartHeight),
      axisPaint,
    );

    for (int i = 0; i < data.length; i++) {
      final ChartDataPoint p = data[i];
      final double normalized = p.value / maxValue;
      final double barHeight = normalized * chartHeight;
      final double left = i * slotWidth + _barInset;
      final double right = (i + 1) * slotWidth - _barInset;
      final double top = _topPadding + chartHeight - barHeight;
      final double bottom = _topPadding + chartHeight;

      final Paint barPaint = Paint()
        ..color = i == hoveredIndex
            ? ScalarioColors.primary700
            : ScalarioColors.primary500;
      final RRect rrect = RRect.fromLTRBAndCorners(
        left,
        top,
        right,
        bottom,
        topLeft: const Radius.circular(ScalarioRadius.sm),
        topRight: const Radius.circular(ScalarioRadius.sm),
      );
      canvas.drawRRect(rrect, barPaint);

      // Label en bas (axe X).
      final TextPainter labelPainter = TextPainter(
        text: TextSpan(text: p.label, style: axisLabelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: slotWidth);
      labelPainter.paint(
        canvas,
        Offset(
          i * slotWidth + (slotWidth - labelPainter.width) / 2,
          _topPadding + chartHeight + 8,
        ),
      );

      // Tooltip valeur au-dessus de la barre hovered.
      if (i == hoveredIndex) {
        final String label = unit != null
            ? '${_formatValue(p.value)} $unit'
            : _formatValue(p.value);
        final TextPainter valuePainter = TextPainter(
          text: TextSpan(text: label, style: valueLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        valuePainter.paint(
          canvas,
          Offset(
            i * slotWidth + (slotWidth - valuePainter.width) / 2,
            top - valuePainter.height - 4,
          ),
        );
      }
    }
  }

  String _formatValue(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.unit != unit;
  }
}
