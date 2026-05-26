import { Injectable, Logger } from '@nestjs/common';

export type VaultStep = () => Promise<void>;

/**
 * VaultTransactionService — Phase 1 stub.
 *
 * execute(steps) runs steps sequentially. If any step throws, previously
 * completed steps are rolled back in reverse order.
 *
 * Phase 2+ will wrap steps in a database transaction or saga pattern.
 */
@Injectable()
export class VaultTransactionService {
  private readonly logger = new Logger(VaultTransactionService.name);

  async execute(steps: VaultStep[]): Promise<void> {
    const completed: VaultStep[] = [];

    for (const [i, step] of steps.entries()) {
      try {
        this.logger.log(`[STUB] running step ${i + 1}/${steps.length}`);
        await step();
        completed.push(step);
      } catch (err) {
        this.logger.error(`[STUB] step ${i + 1} failed: ${(err as Error).message}`);
        await this.rollback(completed);
        throw err;
      }
    }

    this.logger.log(`[STUB] all ${steps.length} steps completed`);
  }

  private async rollback(completed: VaultStep[]): Promise<void> {
    for (const step of completed.reverse()) {
      try {
        this.logger.warn(`[STUB] rolling back step`);
        await step();
      } catch (rollbackErr) {
        this.logger.error(`[STUB] rollback failed: ${(rollbackErr as Error).message}`);
      }
    }
  }
}
