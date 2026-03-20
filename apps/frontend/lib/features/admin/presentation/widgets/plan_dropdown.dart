import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';

class PlanDropdown extends ConsumerWidget {
  final String? value;
  final ValueChanged<Map<String, dynamic>?> onPlanSelected;

  const PlanDropdown({
    super.key,
    required this.value,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(planDefinitionsProvider);

    return plansAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (plans) {
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(
            labelText: 'Plan',
            border: OutlineInputBorder(),
          ),
          items: plans
              .map((p) => DropdownMenuItem<String>(
                    value: p['code'] as String,
                    child: Text(
                        '${p['name']} — ${p['monthlyPrice']} FCFA/mois'),
                  ))
              .toList(),
          onChanged: (code) {
            final plan = plans.firstWhere(
              (p) => p['code'] == code,
              orElse: () => plans.first,
            );
            onPlanSelected(plan);
          },
        );
      },
    );
  }
}
