import { Module } from '@nestjs/common';
import { WorkflowValidatorService } from './validator/workflow-validator.service';

@Module({
  providers: [WorkflowValidatorService],
  exports: [WorkflowValidatorService],
})
export class WorkflowModule {}
