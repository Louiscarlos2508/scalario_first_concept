import { Controller, Post, Body, Req } from '@nestjs/common';
import { RetailOrchestrationService } from './retail-orchestration.service';
import { RequiresModule } from '../kernel/modules/module.decorator';
import { Roles } from '../kernel/rbac/roles.decorator';

@Controller('retail/sales')
@RequiresModule('retail')
export class RetailController {
  constructor(private readonly orchestrationService: RetailOrchestrationService) {}

  // AC2 — POST /retail/sales: atomic sale (Transaction + RetailSale + events)
  @Post()
  @Roles('owner', 'manager', 'commercial')
  async createSale(
    @Body()
    body: {
      transactionId?: string;
      totalAmount: number;
      items?: any[];
      paymentMethod?: string;
      paymentSplits?: any;
      customerId?: string | null;
      sessionId?: string | null;
      receiptNumber?: string;
      tenantId: string;
      // Date de vente locale du device (POS offline-first).
      // Si absent → now() par défaut (vente en ligne directe).
      createdAt?: string;
    },
    @Req() req: any,
  ) {
    const userId = req.user?.id ?? null;
    return this.orchestrationService.createSale({
      ...body,
      cashierId: userId,
      userId,
    });
  }
}
