import type { WorkflowStep } from '../workflow-validator.types';

export const orphanDependencyFixture: WorkflowStep[] = [
  { id: 'A', type: 'action', dependsOn: [], action: 'start' },
  { id: 'B', type: 'action', dependsOn: ['A'], action: 'step_b' },
  { id: 'C', type: 'action', dependsOn: ['ZZ'], action: 'step_c' },
];
