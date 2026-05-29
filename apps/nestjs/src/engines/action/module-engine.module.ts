import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FlowModule } from '../flow/flow.module';
import { ModuleEngineController } from './module-engine.controller';
import { ModuleResolverService } from './services/module-resolver.service';
import { DataDispatcherService } from './services/data-dispatcher.service';
import { ActionDispatcherService } from './services/action-dispatcher.service';
import { IdempotencyService } from './services/idempotency.service';
import { HandlerRegistry } from './handlers/handler-registry';
import { CrudCreateHandler } from './handlers/crud-create.handler';
import { CrudUpdateHandler } from './handlers/crud-update.handler';
import { CrudDeleteHandler } from './handlers/crud-delete.handler';
import { WorkflowAdvanceHandler } from './handlers/workflow-advance.handler';
import { FlowExecuteHandler } from './handlers/flow-execute.handler';
import { WorkflowResponseMapper } from './workflow-response.mapper';
import { EntityRecord } from './entities/entity.entity';
import { SyncMutation } from './entities/sync-mutation.entity';
import { WorkflowModule } from '../workflow/workflow.module';

@Module({
  imports: [TypeOrmModule.forFeature([EntityRecord, SyncMutation]), WorkflowModule, FlowModule],
  controllers: [ModuleEngineController],
  providers: [
    ModuleResolverService,
    DataDispatcherService,
    ActionDispatcherService,
    IdempotencyService,
    HandlerRegistry,
    CrudCreateHandler,
    CrudUpdateHandler,
    CrudDeleteHandler,
    WorkflowAdvanceHandler,
    FlowExecuteHandler,
    WorkflowResponseMapper,
  ],
  exports: [
    ModuleResolverService,
    DataDispatcherService,
    ActionDispatcherService,
    IdempotencyService,
  ],
})
export class ModuleEngineModule {
  constructor(
    private readonly registry: HandlerRegistry,
    private readonly crudCreate: CrudCreateHandler,
    private readonly crudUpdate: CrudUpdateHandler,
    private readonly crudDelete: CrudDeleteHandler,
    private readonly workflowAdvance: WorkflowAdvanceHandler,
    private readonly flowExecute: FlowExecuteHandler,
  ) {
    this.registry.register(this.crudCreate);
    this.registry.register(this.crudUpdate);
    this.registry.register(this.crudDelete);
    this.registry.register(this.workflowAdvance);
    this.registry.register(this.flowExecute);
  }
}
