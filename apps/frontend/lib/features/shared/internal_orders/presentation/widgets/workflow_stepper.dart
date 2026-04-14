import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/shared/internal_orders/data/internal_order.dart';

/// Workflow stepper horizontal — 3 étapes (Commercial → Gérante → Patronne).
///
/// Chaque cercle : vert ✓ (completed), bleu + numéro (current), gris + numéro (pending).
/// Lignes de connexion colorées selon l'état.
class WorkflowStepper extends StatelessWidget {
  final List<WorkflowStep> steps;
  final bool showLabels;

  const WorkflowStepper({
    super.key,
    required this.steps,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepCircle(step: steps[i], showLabel: showLabels),
          if (i < steps.length - 1)
            _StepLine(from: steps[i], hasLabels: showLabels),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  final WorkflowStep step;
  final bool showLabel;

  const _StepCircle({required this.step, required this.showLabel});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Widget child;

    switch (step.state) {
      case WfStepState.completed:
        bg = AppColors.success;
        child = const Text('✓',
            style: TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
      case WfStepState.current:
        bg = AppColors.primary;
        child = Text('${step.stepNumber}',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
      case WfStepState.pending:
        bg = const Color(0xFFE5E7EB);
        child = Text('${step.stepNumber}',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          alignment: Alignment.center,
          child: child,
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            step.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  step.state == WfStepState.current ? FontWeight.w700 : FontWeight.w500,
              color: step.state == WfStepState.current
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final WorkflowStep from;
  final bool hasLabels;

  const _StepLine({required this.from, this.hasLabels = true});

  @override
  Widget build(BuildContext context) {
    final isCompleted = from.state == WfStepState.completed;
    return Padding(
      // When labels are shown, offset line up so it aligns with circles, not labels.
      padding: EdgeInsets.only(bottom: hasLabels ? 18 : 0),
      child: Container(
        width: 16,
        height: 2,
        color: isCompleted ? AppColors.success : const Color(0xFFE5E7EB),
      ),
    );
  }
}
