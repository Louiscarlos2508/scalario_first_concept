import { Logger } from '@nestjs/common';

export interface RetryResult<T> {
  result: T;
  attempts: number;
}

export class RetryPolicy {
  private readonly logger = new Logger(RetryPolicy.name);
  private readonly delays: number[];

  constructor(delays?: number[]) {
    this.delays = delays ?? [200, 500, 1500];
  }

  async execute<T>(fn: () => Promise<T>, opts: { stepId: string }): Promise<RetryResult<T>> {
    let lastError: unknown;
    let attempts = 0;

    for (let attempt = 0; attempt <= this.delays.length; attempt++) {
      attempts++;
      try {
        const result = await fn();
        return { result, attempts };
      } catch (err) {
        lastError = err;

        if (this.isBusinessError(err)) {
          throw err;
        }

        if (!this.isTransient(err) || attempt === this.delays.length) {
          throw err;
        }

        const delay = this.delays[attempt];
        this.logger.warn(
          `Step '${opts.stepId}' failed (attempt ${attempts}), retrying in ${delay}ms: ${(err as Error).message}`,
        );
        await this.sleep(delay);
      }
    }

    throw lastError;
  }

  isTransient(err: unknown): boolean {
    const e = err as Record<string, unknown>;
    if (!e) return false;

    if (e.code === 'ECONNRESET' || e.code === 'ETIMEDOUT') return true;
    if (e.code === 'ECONNREFUSED') return true;

    if (typeof e.status === 'number') {
      return e.status >= 500 && e.status <= 599;
    }

    if (e.name === 'TimeoutError' || e.name === 'NetworkError') return true;

    return false;
  }

  private isBusinessError(err: unknown): boolean {
    const e = err as Record<string, unknown>;
    if (!e) return false;

    if (e.name === 'WorkflowExecutionError') return true;

    if (typeof e.status === 'number' && e.status >= 400 && e.status < 500) {
      return true;
    }

    return false;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
