import { Injectable, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

@Injectable()
export class SoftDeleteService {
  private readonly logger = new Logger(SoftDeleteService.name);

  constructor(@InjectDataSource() private readonly ds: DataSource) {}

  async softDelete(table: string, where: Record<string, unknown>): Promise<void> {
    const clauses = Object.keys(where).map((k, i) => `${k} = $${i + 1}`);
    const params = Object.values(where);
    const query = `UPDATE ${table} SET deleted_at = NOW() WHERE ${clauses.join(' AND ')} AND deleted_at IS NULL`;
    await this.ds.query(query, params);
    this.logger.log(`Soft deleted from ${table}: ${JSON.stringify(where)}`);
  }

  async restore(table: string, where: Record<string, unknown>): Promise<void> {
    const clauses = Object.keys(where).map((k, i) => `${k} = $${i + 1}`);
    const params = Object.values(where);
    const query = `UPDATE ${table} SET deleted_at = NULL WHERE ${clauses.join(' AND ')}`;
    await this.ds.query(query, params);
    this.logger.log(`Restored in ${table}: ${JSON.stringify(where)}`);
  }

  buildSoftDeleteQuery(table: string, baseWhere = ''): { where: string; params: unknown[] } {
    const filter = `${baseWhere ? `${baseWhere} AND ` : 'WHERE '}deleted_at IS NULL`;
    return { where: filter, params: [] };
  }
}
