import 'package:flutter/material.dart';

import '../../core/design_system/tokens/tokens.dart';
import '../../engine/canvas_registry/component_config.dart';

/// Composant de classement de données (ex: Top 5 produits).
///
/// **Rôle :** Affiche une liste ordonnée d'éléments (classement) dans une carte
/// élégante avec des badges de rangs, des noms et des indicateurs de quantité/montant.
///
/// **Usage BDUI :**
/// ```json
/// {
///   "type": "RankingList",
///   "props": {
///     "title": "Top 5 produits",
///     "items": [
///       { "rank": 1, "name": "Tomates", "qty": "45 kg", "amount": "22 500 FCFA" }
///     ]
///   }
/// }
/// ```
class RankingList extends StatelessWidget {
  final String title;
  final List<dynamic> items;
  final bool showRank;

  const RankingList({
    super.key,
    required this.title,
    required this.items,
    this.showRank = true,
  });

  /// Construit un `RankingList` depuis la configuration BDUI.
  factory RankingList.fromConfig(ComponentConfig config, BuildContext ctx) {
    final props = config.props;
    final String title = props['title'] as String? ?? 'Classement';
    final List<dynamic> items = props['items'] as List<dynamic>? ?? [];
    final bool showRank = props['show_rank'] as bool? ?? true;

    return RankingList(
      title: title,
      items: items,
      showRank: showRank,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ScalarioSpacing.space6),
      decoration: BoxDecoration(
        color: ScalarioColors.bgCard,
        borderRadius: BorderRadius.circular(ScalarioRadius.md),
        border: Border.all(color: ScalarioColors.borderDefault),
        boxShadow: ScalarioElevation.e1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: ScalarioTypography.fontSectionTitle),
          const SizedBox(height: ScalarioSpacing.space4),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ScalarioSpacing.space4),
              child: Center(
                child: Text(
                  'Aucune donnée disponible',
                  style: ScalarioTypography.caption.copyWith(
                    color: ScalarioColors.textDisabled,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(
                color: ScalarioColors.borderDefault,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final dynamic rawItem = items[index];
                if (rawItem is! Map<String, dynamic>) {
                  return const SizedBox.shrink();
                }

                final item = rawItem;
                final rankVal = item['rank'];
                final String name = item['name'] as String? ?? 'Inconnu';
                final String? qty = item['qty'] as String?;
                final String? amount = item['amount'] as String?;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: ScalarioSpacing.space3),
                  child: Row(
                    children: [
                      if (showRank && rankVal != null) ...[
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: ScalarioColors.neutral100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              rankVal.toString(),
                              style: ScalarioTypography.bodyMedium.copyWith(
                                color: ScalarioColors.neutral700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: ScalarioSpacing.space3),
                      ],
                      Expanded(
                        child: Text(
                          name,
                          style: ScalarioTypography.bodyMedium.copyWith(
                            color: ScalarioColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: ScalarioSpacing.space3),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (amount != null)
                            Text(
                              amount,
                              style: ScalarioTypography.bodyMediumMono.copyWith(
                                color: ScalarioColors.textPrimary,
                              ),
                            ),
                          if (qty != null)
                            Text(
                              qty,
                              style: ScalarioTypography.caption.copyWith(
                                color: ScalarioColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
