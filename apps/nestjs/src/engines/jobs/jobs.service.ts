import { Injectable, Logger } from '@nestjs/common';

/**
 * JobsService — Phase 1 stub for BullMQ job queue integration.
 *
 * enqueue(name, data) logs and returns a synthetic jobId.
 * getStatus(jobId) always returns 'completed' in this stub.
 *
 * Phase 2+ will wire @nestjs/bull or a raw BullMQ Queue and provide
 * real status tracking via Redis/Postgres.
 */
@Injectable()
export class JobsService {
  private readonly logger = new Logger(JobsService.name);

  async enqueue(jobName: string, data: Record<string, unknown>): Promise<string> {
    const jobId = `${jobName}:${Date.now()}:${Math.random().toString(36).slice(2, 9)}`;
    this.logger.log(`[STUB] enqueue job=${jobName} jobId=${jobId} data=${JSON.stringify(data)}`);
    return jobId;
  }

  async getStatus(jobId: string): Promise<string> {
    this.logger.log(`[STUB] getStatus jobId=${jobId}`);
    return 'completed';
  }
}
