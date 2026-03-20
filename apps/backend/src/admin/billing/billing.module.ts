import { Module } from '@nestjs/common';
import { PlanDefinitionService } from './plan-definition.service';
import { PlanDefinitionController } from './plan-definition.controller';
import { TenantPlanService } from './tenant-plan.service';
import { TenantPlanController } from './tenant-plan.controller';
import { BillingEventsService } from './billing-events.service';
import { BillingEventsController } from './billing-events.controller';
import { BillingSchedulerService } from './billing-scheduler.service';
import { SettingsBillingController } from './settings-billing.controller';
import { ModulesModule } from '../../kernel/modules/modules.module';

@Module({
  imports: [ModulesModule],
  controllers: [
    PlanDefinitionController,
    TenantPlanController,
    BillingEventsController,
    SettingsBillingController,
  ],
  providers: [
    PlanDefinitionService,
    TenantPlanService,
    BillingEventsService,
    BillingSchedulerService,
  ],
  exports: [PlanDefinitionService, TenantPlanService, BillingEventsService],
})
export class BillingModule {}
