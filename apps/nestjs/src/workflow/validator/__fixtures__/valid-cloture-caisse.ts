import type { WorkflowStep } from '../workflow-validator.types';

export const clotureCaisseFixture: WorkflowStep[] = [
  { id: 'saisie_fond_restant', type: 'action', action: 'open_form_fond' },
  {
    id: 'reconciliation',
    type: 'action',
    dependsOn: ['saisie_fond_restant'],
    action: 'compute_diff',
  },
  { id: 'validation_manager', type: 'approval', dependsOn: ['reconciliation'] },
  {
    id: 'cloture_confirmee',
    type: 'notification',
    dependsOn: ['validation_manager'],
    action: 'notify_owner',
  },
];
