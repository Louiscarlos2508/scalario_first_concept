import type { WorkflowStep } from '../workflow-validator.types';

export const cycleSimpleFixture: WorkflowStep[] = [
  { id: 'A', type: 'action', dependsOn: ['B'], action: 'do_a' },
  { id: 'B', type: 'action', dependsOn: ['A'], action: 'do_b' },
];
