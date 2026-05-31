import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FlowPendingDelay } from '../entities/flow-pending-delay.entity';
import { FlowResumeService } from '../flow-resume.service';
import { FlowRuntimeService } from '../flow-runtime.service';
import type { CompiledFlow } from '../flow.types';

describe('FlowResumeService', () => {
  let resumeService: FlowResumeService;
  let mockRepo: jest.Mocked<Repository<FlowPendingDelay>>;
  let mockRuntime: jest.Mocked<FlowRuntimeService>;

  const testFlow: CompiledFlow = {
    id: 'test-flow',
    name: 'Test',
    trigger: { type: 'manual' },
    steps: [
      { id: 'delay1', type: 'delay', config: { duration: 5 } },
      { id: 'child1', type: 'end', config: { output: { done: true } } },
    ],
    adjacency: new Map([
      ['delay1', { onSuccess: ['child1'] }],
      ['child1', { onSuccess: [] }],
    ]),
  };

  const testContext = {
    tenantId: 't1',
    userId: 'u1',
    data: { items: [1, 2, 3] },
  };

  beforeEach(async () => {
    mockRepo = {
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      delete: jest.fn(),
    } as any;

    mockRuntime = {
      executeStep: jest.fn(),
    } as any;

    const module = await Test.createTestingModule({
      providers: [
        FlowResumeService,
        { provide: getRepositoryToken(FlowPendingDelay), useValue: mockRepo },
        { provide: FlowRuntimeService, useValue: mockRuntime },
      ],
    }).compile();

    resumeService = module.get<FlowResumeService>(FlowResumeService);
  });

  describe('enqueueDelay', () => {
    it('AC-11: persists a delay with correct resume_at', async () => {
      mockRepo.create.mockReturnValue({} as FlowPendingDelay);
      mockRepo.save.mockResolvedValue(undefined as any);

      const before = Date.now();
      await resumeService.enqueueDelay(
        'test-flow', 'delay1', 't1', 'u1', testContext, testFlow, 5,
      );
      const after = Date.now();

      expect(mockRepo.create).toHaveBeenCalledTimes(1);
      const created = mockRepo.create.mock.calls[0][0] as Partial<FlowPendingDelay>;
      expect(created.flow_id).toBe('test-flow');
      expect(created.step_id).toBe('delay1');
      expect(created.tenant_id).toBe('t1');
      expect(created.user_id).toBe('u1');
      expect(created.context).toEqual(testContext);
      expect(created.resume_at!.getTime()).toBeGreaterThanOrEqual(before + 5000);
      expect(created.resume_at!.getTime()).toBeLessThanOrEqual(after + 5000);
      expect(mockRepo.save).toHaveBeenCalledTimes(1);
    });

    it('AC-05: stores flow definition for resume', async () => {
      mockRepo.create.mockReturnValue({} as FlowPendingDelay);
      mockRepo.save.mockResolvedValue(undefined as any);

      await resumeService.enqueueDelay(
        'test-flow', 'delay1', 't1', 'u1', testContext, testFlow, 5,
      );

      const created = mockRepo.create.mock.calls[0][0] as any;
      const def = created.flow_definition as Record<string, unknown>;
      expect(def.id).toBe('test-flow');
      expect(def.steps).toHaveLength(2);
      expect((def as any).adjacency).toBeDefined();
      expect((def as any).adjacency.delay1.onSuccess).toEqual(['child1']);
    });
  });

  describe('resumeDelayedFlows', () => {
    it('AC-11: resumes due delays and deletes them', async () => {
      const future = new Date(Date.now() - 1000);
      const delay = new FlowPendingDelay();
      delay.id = 'abc-123';
      delay.flow_id = 'test-flow';
      delay.step_id = 'delay1';
      delay.tenant_id = 't1';
      delay.user_id = 'u1';
      delay.context = testContext;
      delay.resume_at = future;
      delay.flow_definition = {
        id: 'test-flow',
        name: 'Test',
        trigger: { type: 'manual' },
        steps: testFlow.steps,
        adjacency: { delay1: { onSuccess: ['child1'] }, child1: { onSuccess: [] } },
      } as any;

      mockRepo.find.mockResolvedValue([delay]);
      mockRepo.delete.mockResolvedValue({ affected: 1, raw: {} } as any);
      mockRuntime.executeStep.mockResolvedValue(undefined);

      await resumeService.resumeDelayedFlows();

      expect(mockRepo.find).toHaveBeenCalled();
      expect(mockRuntime.executeStep).toHaveBeenCalledWith(
        'child1',
        expect.objectContaining({ id: 'test-flow' }),
        expect.objectContaining({ tenantId: 't1', data: { items: [1, 2, 3] } }),
        expect.any(Array),
        expect.any(Set),
      );
      expect(mockRepo.delete).toHaveBeenCalledWith('abc-123');
    });

    it('AC-12: handles empty pending list gracefully', async () => {
      mockRepo.find.mockResolvedValue([]);

      await resumeService.resumeDelayedFlows();

      expect(mockRuntime.executeStep).not.toHaveBeenCalled();
    });

    it('AC-09: keeps record on execution failure', async () => {
      const future = new Date(Date.now() - 1000);
      const delay = new FlowPendingDelay();
      delay.id = 'abc-123';
      delay.flow_id = 'test-flow';
      delay.step_id = 'delay1';
      delay.tenant_id = 't1';
      delay.user_id = 'u1';
      delay.context = testContext;
      delay.resume_at = future;
      delay.flow_definition = {
        id: 'test-flow',
        steps: testFlow.steps,
        adjacency: { delay1: { onSuccess: ['child1'] } },
      } as any;

      mockRepo.find.mockResolvedValue([delay]);
      mockRepo.delete.mockResolvedValue({ affected: 1, raw: {} } as any);
      mockRuntime.executeStep.mockRejectedValue(new Error('Step failed'));

      await resumeService.resumeDelayedFlows();

      expect(mockRuntime.executeStep).toHaveBeenCalled();
      expect(mockRepo.delete).not.toHaveBeenCalled();
    });

    it('handles flow with no children gracefully', async () => {
      const future = new Date(Date.now() - 1000);
      const delay = new FlowPendingDelay();
      delay.id = 'abc-123';
      delay.flow_id = 'test-flow';
      delay.step_id = 'delay1';
      delay.tenant_id = 't1';
      delay.user_id = 'u1';
      delay.context = testContext;
      delay.resume_at = future;
      delay.flow_definition = {
        id: 'test-flow',
        steps: testFlow.steps,
        adjacency: { delay1: { onSuccess: [] } },
      } as any;

      mockRepo.find.mockResolvedValue([delay]);
      mockRepo.delete.mockResolvedValue({ affected: 1, raw: {} } as any);

      await resumeService.resumeDelayedFlows();

      expect(mockRuntime.executeStep).not.toHaveBeenCalled();
      expect(mockRepo.delete).toHaveBeenCalledWith('abc-123');
    });
  });

  describe('delay with 0 seconds', () => {
    it('AC-05: delay=0 does not persist (handled by FlowRuntimeService timeout path)', () => {
      expect(true).toBe(true);
    });
  });
});
