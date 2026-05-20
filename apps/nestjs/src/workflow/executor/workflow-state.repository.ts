import { Injectable, Logger } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { WorkflowStateEntity } from './workflow-state.entity';
import type { StepExecution } from './workflow-executor.types';

export interface CreateWorkflowStateInput {
  tenantId: string;
  runId: string;
  workflowId: string;
  entityId?: string;
  triggeredBy?: string;
  currentState: string;
  history: StepExecution[];
}

export interface UpdateWorkflowStateInput {
  currentState: string;
  history: StepExecution[];
}

@Injectable()
export class WorkflowStateRepository {
  private readonly logger = new Logger(WorkflowStateRepository.name);
  private readonly repo: Repository<WorkflowStateEntity>;

  constructor(private readonly dataSource: DataSource) {
    this.repo = dataSource.getRepository(WorkflowStateEntity);
  }

  async create(input: CreateWorkflowStateInput): Promise<WorkflowStateEntity> {
    const entity = this.repo.create({
      id: input.runId,
      tenant_id: input.tenantId,
      entity_id: input.entityId ?? null,
      workflow_id: input.workflowId,
      current_state: input.currentState,
      history: input.history as any,
      triggered_by: input.triggeredBy ?? null,
    });
    return this.repo.save(entity);
  }

  async update(runId: string, input: UpdateWorkflowStateInput): Promise<WorkflowStateEntity> {
    return this.dataSource.transaction(async (manager) => {
      await manager.update(WorkflowStateEntity, runId, {
        current_state: input.currentState,
        history: input.history as any,
        updated_at: new Date(),
      });
      return manager.findOneOrFail(WorkflowStateEntity, { where: { id: runId } });
    });
  }

  async findByRunId(runId: string): Promise<WorkflowStateEntity | null> {
    return this.repo.findOne({ where: { id: runId } });
  }

  async findByEntityAndWorkflow(
    tenantId: string,
    entityId: string,
    workflowId: string,
  ): Promise<WorkflowStateEntity | null> {
    return this.repo.findOne({
      where: { tenant_id: tenantId, entity_id: entityId, workflow_id: workflowId },
    });
  }
}
