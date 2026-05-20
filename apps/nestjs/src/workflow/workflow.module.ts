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
  ],
  exports: [WorkflowValidatorService, WorkflowExecutorService],
})
export class WorkflowModule {}
