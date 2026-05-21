import { z } from 'zod';

export const SyncMutationItemSchema = z.object({
  mutation_id: z.string().uuid(),
  module_id: z.string().min(1),
  action: z.string().min(1),
  payload: z.record(z.unknown()).default({}),
});

export const SyncMutationsBatchSchema = z.object({
  mutations: z.array(SyncMutationItemSchema).min(1).max(20),
});

export type SyncMutationItem = z.infer<typeof SyncMutationItemSchema>;
export type SyncMutationsBatch = z.infer<typeof SyncMutationsBatchSchema>;

export interface SyncResultItem {
  mutation_id: string;
  status: 'success' | 'error' | 'conflict';
  entity?: Record<string, unknown>;
  error?: string;
}

export interface SyncBatchResponse {
  results: SyncResultItem[];
}
