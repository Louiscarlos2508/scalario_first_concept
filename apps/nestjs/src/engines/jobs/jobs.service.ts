import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Queue, Worker, QueueScheduler } from 'bullmq';
import { RedisService } from '../../core/cache/services/redis.service';

@Injectable()
export class JobsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(JobsService.name);
  private queue: Queue | null = null;
  private scheduler: QueueScheduler | null = null;

  constructor(private readonly redis: RedisService) {}

  async onModuleInit() {
    if (!this.redis.isAvailable()) {
      this.logger.warn('Redis not available, jobs will be logged only');
      return;
    }

    const connection = { host: 'redis', port: 6379 };
    this.queue = new Queue('scalario-jobs', { connection });
    this.scheduler = new QueueScheduler('scalario-jobs', { connection });

    new Worker('scalario-jobs', async (job) => {
      this.logger.log(`Processing job ${job.id}: ${job.name}`);
      switch (job.name) {
        case 'generate_pdf':
          this.logger.log(`[STUB] Generate PDF: ${JSON.stringify(job.data)}`);
          break;
        case 'send_email':
          this.logger.log(`[STUB] Send email: ${JSON.stringify(job.data)}`);
          break;
        case 'compute_report':
          this.logger.log(`[STUB] Compute report: ${JSON.stringify(job.data)}`);
          break;
        default:
          this.logger.log(`[STUB] Unknown job: ${job.name}`);
      }
    }, { connection });

    this.logger.log('BullMQ jobs service initialized');
  }

  async onModuleDestroy() {
    await this.queue?.close();
    await this.scheduler?.close();
  }

  async enqueue(name: string, data: Record<string, unknown>): Promise<string> {
    if (!this.queue) {
      const jobId = `stub-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
      this.logger.log(`[NO-QUEUE] Enqueue ${name}: ${jobId}`);
      return jobId;
    }
    const job = await this.queue.add(name, data);
    this.logger.log(`Enqueued ${name}: ${job.id}`);
    return job.id!;
  }

  async getStatus(jobId: string): Promise<string> {
    if (!this.queue) return 'completed';
    const job = await this.queue.getJob(jobId);
    if (!job) return 'not_found';
    const state = await job.getState();
    return state;
  }
}
