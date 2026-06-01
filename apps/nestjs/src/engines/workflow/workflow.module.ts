import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkflowValidatorService } from './validator/workflow-validator.service';
import { WorkflowExecutorService } from './executor/workflow-executor.service';
import { StepDispatcher } from './executor/step-dispatcher';
import { ConditionEvaluator } from './executor/condition-evaluator';
import { RetryPolicy } from './executor/retry-policy';
import { ActionDispatcher } from './executor/action-dispatcher';
import { WorkflowStateRepository } from './executor/workflow-state.repository';
import { NotificationQueue } from './executor/notification-queue';
import { WorkflowStateEntity } from './executor/workflow-state.entity';
import { FsmBuilder } from './fsm/fsm-builder';
import { FsmValidator } from './fsm/fsm-validator';
import { WorkflowFsmService } from './fsm/workflow-fsm.service';
import { WorkflowDefinitionResolver } from './fsm/workflow-definition.resolver';
import { WorkflowController } from './workflow.controller';
import { AuditModule } from '../../core/audit/audit.module';
import { SecurityModule } from '../../core/security/security.module';
import { DatabaseModule } from '../../common/database.module';
import { ACTION_DISPATCHER, NOTIFICATION_QUEUE } from './executor/workflow-executor.types';

@Module({
  imports: [DatabaseModule, AuditModule, SecurityModule, TypeOrmModule.forFeature([WorkflowStateEntity])],
  providers: [
    WorkflowValidatorService,
    WorkflowExecutorService,
    StepDispatcher,
    ConditionEvaluator,
    RetryPolicy,
    WorkflowStateRepository,
    NotificationQueue,
    ActionDispatcher,
    { provide: ACTION_DISPATCHER, useClass: ActionDispatcher },
    { provide: NOTIFICATION_QUEUE, useExisting: NotificationQueue },
    FsmBuilder,
    FsmValidator,
    WorkflowFsmService,
    WorkflowDefinitionResolver,
  ],
  controllers: [WorkflowController],
  exports: [
    WorkflowValidatorService,
    WorkflowExecutorService,
    WorkflowFsmService,
    WorkflowStateRepository,
  ],
})
export class WorkflowModule {}
