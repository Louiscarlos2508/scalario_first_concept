import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { WorkflowValidatorService } from './validator/workflow-validator.service';
import { WorkflowExecutorService } from './executor/workflow-executor.service';
import { StepDispatcher } from './executor/step-dispatcher';
import { ConditionEvaluator } from './executor/condition-evaluator';
import { RetryPolicy } from './executor/retry-policy';
import { WorkflowStateRepository } from './executor/workflow-state.repository';
import { NotificationQueue } from './executor/notification-queue';
import { WorkflowStateEntity } from './executor/workflow-state.entity';
import { FsmBuilder } from './fsm/fsm-builder';
import { FsmValidator } from './fsm/fsm-validator';
import { WorkflowFsmService } from './fsm/workflow-fsm.service';
import { WorkflowDefinitionResolver } from './fsm/workflow-definition.resolver';
import { WorkflowController } from './workflow.controller';
import { AuditModule } from '../audit/audit.module';
import { DatabaseModule } from '../common/database.module';

@Module({
  imports: [DatabaseModule, AuditModule, TypeOrmModule.forFeature([WorkflowStateEntity])],
  providers: [
    WorkflowValidatorService,
    WorkflowExecutorService,
    StepDispatcher,
    ConditionEvaluator,
    RetryPolicy,
    WorkflowStateRepository,
    NotificationQueue,
    FsmBuilder,
    FsmValidator,
    WorkflowFsmService,
    WorkflowDefinitionResolver,
  ],
  controllers: [WorkflowController],
  exports: [WorkflowValidatorService, WorkflowExecutorService, WorkflowFsmService],
})
export class WorkflowModule {}
