import { Injectable } from '@nestjs/common';
import { PromotionsService } from './promotions.service';

export interface AppliedPromotion {
  id: string;
  type: string;
  originalPrice: number;
  discountedPrice: number;
  discountAmount: number;
  freeQty?: number;
}

@Injectable()
export class PromotionEngineService {
  constructor(private readonly promotionsService: PromotionsService) {}

  /**
   * Evaluate applicable promotions for a cart line.
   * Returns the best AppliedPromotion or null.
   */
  async evaluate(params: {
    catalogItemId: string;
    categoryId?: string | null;
    quantity: number;
    unitPrice: number;
    tenantId: string;
  }): Promise<AppliedPromotion | null> {
    const promos = await this.promotionsService.getActivePromotionsForItem(
      params.tenantId,
      params.catalogItemId,
      params.categoryId,
    );

    if (promos.length === 0) return null;

    const evaluated: AppliedPromotion[] = [];

    for (const promo of promos) {
      const value = promo.value as Record<string, any>;

      switch (promo.type) {
        case 'PERCENT': {
          const pct = Number(value['percent'] ?? 0);
          const discount = params.unitPrice * (pct / 100);
          evaluated.push({
            id: promo.id,
            type: 'PERCENT',
            originalPrice: params.unitPrice,
            discountedPrice: params.unitPrice - discount,
            discountAmount: discount,
          });
          break;
        }
        case 'BUY_N_GET_M': {
          const buyN = Number(value['buyN'] ?? 0);
          if (params.quantity >= buyN) {
            const getM = Number(value['getM'] ?? 0);
            // Treat as a per-unit average discount
            const totalDiscount = getM * params.unitPrice;
            const perUnitDiscount = totalDiscount / params.quantity;
            evaluated.push({
              id: promo.id,
              type: 'BUY_N_GET_M',
              originalPrice: params.unitPrice,
              discountedPrice: params.unitPrice - perUnitDiscount,
              discountAmount: perUnitDiscount,
              freeQty: getM,
            });
          }
          break;
        }
        case 'CROSSED_PRICE': {
          const newPrice = Number(value['newPrice'] ?? params.unitPrice);
          const discount = params.unitPrice - newPrice;
          if (discount > 0) {
            evaluated.push({
              id: promo.id,
              type: 'CROSSED_PRICE',
              originalPrice: params.unitPrice,
              discountedPrice: newPrice,
              discountAmount: discount,
            });
          }
          break;
        }
      }
    }

    if (evaluated.length === 0) return null;

    // BEST: pick highest discount
    const conflictRule = promos[0]?.conflictRule ?? 'BEST';
    if (conflictRule === 'FIRST') return evaluated[0];
    return evaluated.reduce((a, b) => (a.discountAmount > b.discountAmount ? a : b));
  }
}
