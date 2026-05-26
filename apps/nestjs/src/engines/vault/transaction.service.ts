import { Injectable, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, QueryRunner } from 'typeorm';

interface VaultStep {
  fn: string;
  source: string;
  where?: Record<string, unknown>;
  data?: Record<string, unknown>;
  output?: string;
}

@Injectable()
export class VaultTransactionService {
  private readonly logger = new Logger(VaultTransactionService.name);

  constructor(@InjectDataSource() private readonly ds: DataSource) {}

  async execute(steps: VaultStep[], rollbackOnError = true): Promise<Record<string, unknown>> {
    const queryRunner = this.ds.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    const outputs: Record<string, unknown> = {};
    const executedSteps: Array<{ step: VaultStep; query: string }> = [];

    try {
      for (const step of steps) {
        const result = await this.executeStep(queryRunner, step);
        if (step.output) {
          outputs[step.output] = result;
        }
        executedSteps.push({ step, query: step.fn });
      }

      await queryRunner.commitTransaction();
      this.logger.log(`Transaction committed: ${steps.length} steps`);
      return outputs;
    } catch (err) {
      this.logger.error(`Transaction failed, rolling back: ${(err as Error).message}`);
      if (rollbackOnError) {
        await queryRunner.rollbackTransaction();
      }
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  private async executeStep(qr: QueryRunner, step: VaultStep): Promise<unknown> {
    switch (step.fn) {
      case 'create': {
        const columns = Object.keys(step.data ?? {});
        const values = Object.values(step.data ?? {});
        const placeholders = values.map((_, i) => `$${i + 1}`);
        const query = `INSERT INTO ${step.source} (${columns.join(', ')}) VALUES (${placeholders.join(', ')}) RETURNING *`;
        const result = await qr.query(query, values);
        return result[0];
      }
      case 'update': {
        if (!step.where || !step.data) throw new Error('update requires where and data');
        const sets = Object.keys(step.data).map((k, i) => `${k} = $${i + 1}`);
        const whereClauses = Object.keys(step.where).map((k, i) => `${k} = $${sets.length + i + 1}`);
        const params = [...Object.values(step.data), ...Object.values(step.where)];
        const query = `UPDATE ${step.source} SET ${sets.join(', ')} WHERE ${whereClauses.join(' AND ')} RETURNING *`;
        const result = await qr.query(query, params);
        return result[0];
      }
      case 'delete': {
        if (!step.where) throw new Error('delete requires where');
        const whereClauses = Object.keys(step.where).map((k, i) => `${k} = $${i + 1}`);
        const query = `DELETE FROM ${step.source} WHERE ${whereClauses.join(' AND ')}`;
        await qr.query(query, Object.values(step.where));
        return { deleted: true };
      }
      default:
        throw new Error(`Unknown step fn: ${step.fn}`);
    }
  }
}
