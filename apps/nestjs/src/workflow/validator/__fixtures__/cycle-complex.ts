import type { WorkflowStep } from '../workflow-validator.types';

export const cycleComplexFixture: WorkflowStep[] = [
  { id: 'A', type: 'action', dependsOn: [], action: 'start' },
  { id: 'B', type: 'action', dependsOn: ['A'], action: 'step_b' },
  { id: 'C', type: 'action', dependsOn: ['B'], action: 'step_c' },
  { id: 'D', type: 'action', dependsOn: ['C'], action: 'step_d' },
  { id: 'E', type: 'action', dependsOn: ['D', 'B'], action: 'step_e' },
  { id: 'F', type: 'action', dependsOn: ['K'], action: 'step_f' },
  { id: 'G', type: 'action', dependsOn: ['F'], action: 'step_g' },
  { id: 'H', type: 'action', dependsOn: ['G'], action: 'step_h' },
  { id: 'I', type: 'action', dependsOn: ['H'], action: 'step_i' },
  { id: 'J', type: 'action', dependsOn: ['I'], action: 'step_j' },
  { id: 'K', type: 'action', dependsOn: ['J'], action: 'step_k' },
];
