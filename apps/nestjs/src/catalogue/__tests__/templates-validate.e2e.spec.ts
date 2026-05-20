import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { CanActivate } from '@nestjs/common';
import request from 'supertest';
import { CatalogueController } from '../catalogue.controller';
import { CatalogueValidatorService } from '../services/catalogue-validator.service';
import { WorkflowValidatorService } from '../../workflow/validator/workflow-validator.service';
import { JwtAuthGuard } from '../../auth/guards/jwt-auth.guard';

class MockGuard implements CanActivate {
  canActivate(): boolean {
    return true;
  }
}

describe('POST /admin/templates/validate (e2e)', () => {
  let app: INestApplication;
  let server: ReturnType<INestApplication['getHttpServer']>;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [CatalogueController],
      providers: [CatalogueValidatorService, WorkflowValidatorService],
    })
      .overrideGuard(JwtAuthGuard)
      .useClass(MockGuard)
      .compile();

    app = moduleRef.createNestApplication();
    await app.init();
    server = app.getHttpServer();
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns valid:true for a valid domain template with no workflows', async () => {
    await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'test_domain',
          schema_version: '1.0.0',
          name: 'Test Domain',
          entities: [],
        },
        type: 'domain',
      })
      .expect(201)
      .expect({ valid: true });
  });

  it('returns valid:true for a domain with a valid DAG workflow', async () => {
    await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'test_domain',
          schema_version: '1.0.0',
          name: 'Test Domain',
          entities: [],
          workflows: {
            wf_cloture_caisse: {
              id: 'wf_cloture_caisse',
              schema_version: '1.0.0',
              initial_state: 'start',
              states: { start: { transitions: { go: 'end' } }, end: { final: true } },
              steps: {
                step1: { id: 'step1', type: 'action', action: 'open_form' },
                step2: { id: 'step2', type: 'action', dependsOn: ['step1'], action: 'compute' },
                step3: { id: 'step3', type: 'approval', dependsOn: ['step2'] },
                step4: { id: 'step4', type: 'notification', dependsOn: ['step3'] },
              },
            },
          },
        },
        type: 'domain',
      })
      .expect(201)
      .expect({ valid: true });
  });

  it('returns 422 + WF_CYCLE for a domain with a circular workflow', async () => {
    const res = await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'test_domain',
          schema_version: '1.0.0',
          name: 'Test Domain',
          entities: [],
          workflows: {
            wf_circular: {
              id: 'wf_circular',
              schema_version: '1.0.0',
              initial_state: 'start',
              states: { start: { transitions: { go: 'end' } }, end: { final: true } },
              steps: {
                A: { id: 'A', type: 'action', dependsOn: ['B'] },
                B: { id: 'B', type: 'action', dependsOn: ['A'] },
              },
            },
          },
        },
        type: 'domain',
      })
      .expect(422);

    expect(res.body.valid).toBe(false);
    expect(res.body.dagErrors).toBeDefined();
    expect(res.body.dagErrors[0].code).toBe('WF_CYCLE');
  });

  it('returns 422 + WF_UNKNOWN_DEPENDENCY for a domain with orphan dependency', async () => {
    const res = await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'test_domain',
          schema_version: '1.0.0',
          name: 'Test Domain',
          entities: [],
          workflows: {
            wf_orphan: {
              id: 'wf_orphan',
              schema_version: '1.0.0',
              initial_state: 'start',
              states: { start: { transitions: { go: 'end' } }, end: { final: true } },
              steps: {
                A: { id: 'A', type: 'action' },
                B: { id: 'B', type: 'action', dependsOn: ['A'] },
                C: { id: 'C', type: 'action', dependsOn: ['ZZ'] },
              },
            },
          },
        },
        type: 'domain',
      })
      .expect(422);

    expect(res.body.valid).toBe(false);
    expect(res.body.dagErrors).toBeDefined();
    expect(
      res.body.dagErrors.some((e: { code: string }) => e.code === 'WF_UNKNOWN_DEPENDENCY'),
    ).toBe(true);
  });

  it('returns 422 + WF_SELF_LOOP for a self-referencing step', async () => {
    const res = await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'test_domain',
          schema_version: '1.0.0',
          name: 'Test Domain',
          entities: [],
          workflows: {
            wf_self: {
              id: 'wf_self',
              schema_version: '1.0.0',
              initial_state: 'start',
              states: { start: { transitions: { go: 'end' } }, end: { final: true } },
              steps: {
                X: { id: 'X', type: 'action', dependsOn: ['X'] },
              },
            },
          },
        },
        type: 'domain',
      })
      .expect(422);

    expect(res.body.valid).toBe(false);
    expect(res.body.dagErrors[0].code).toBe('WF_SELF_LOOP');
  });

  it('returns 422 + WF_DUPLICATE_ID for duplicate step ids', async () => {
    const res = await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'test_domain',
          schema_version: '1.0.0',
          name: 'Test Domain',
          entities: [],
          workflows: {
            wf_dup: {
              id: 'wf_dup',
              schema_version: '1.0.0',
              initial_state: 'start',
              states: { start: { transitions: { go: 'end' } }, end: { final: true } },
              steps: {
                A: { id: 'A', type: 'action' },
                B: { id: 'A', type: 'action' },
              },
            },
          },
        },
        type: 'domain',
      })
      .expect(422);

    expect(res.body.valid).toBe(false);
    expect(res.body.dagErrors[0].code).toBe('WF_DUPLICATE_ID');
  });

  it('returns 422 for Zod-invalid content before DAG validation', async () => {
    await request(server)
      .post('/admin/templates/validate')
      .send({
        content: { bad: 'data' },
        type: 'domain',
      })
      .expect(422)
      .expect((res: { body: { valid: boolean; errors: unknown } }) => {
        expect(res.body.valid).toBe(false);
        expect(res.body.errors).toBeDefined();
      });
  });

  it('validates a valid workflow type directly', async () => {
    await request(server)
      .post('/admin/templates/validate')
      .send({
        content: {
          id: 'wf_checkout',
          schema_version: '1.0.0',
          initial_state: 'draft',
          states: { draft: { transitions: { submit: 'pending' } } },
        },
        type: 'workflow',
      })
      .expect(201)
      .expect({ valid: true });
  });
});
