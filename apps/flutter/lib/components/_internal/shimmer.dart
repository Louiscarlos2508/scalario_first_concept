import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';

/// Shimmer effect maison — pas de dépendance externe.
///
/// Pourquoi maison plutôt que le package `shimmer` ? Le besoin Sprint 1 est
/// minimal (gradient animé sur un rectangle) et ajouter une dépendance pour
/// ~30 lignes de code n'a pas le ratio. À ré-évaluer si on a besoin de variantes
/// (shapes, durations custom) sur plusieurs composants.
///
/// Utilisation : wrap un `_ShimmerBox(width, height)` dans le layout du widget
/// loading. La couleur de base est `neutral-100`, le highlight `neutral-50`.
class ScalarioShimmer extends StatefulWidget {
  const ScalarioShimmer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ScalarioShimmer> createState() => _ScalarioShimmerState();
}

class _ScalarioShimmerState extends State<ScalarioShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 - 2 * t, 0),
              end: Alignment(1.0 - 2 * t, 0),
              colors: const <Color>[
                ScalarioColors.neutral100,
                ScalarioColors.neutral50,
                ScalarioColors.neutral100,
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Bloc rectangulaire vide réutilisable — utilisé comme contenu d'un `Shimmer`.
class ScalarioShimmerBox extends StatelessWidget {
  const ScalarioShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = ScalarioRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ScalarioColors.neutral100,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}
