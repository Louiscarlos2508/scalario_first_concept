import { Injectable, Logger } from '@nestjs/common';
import { ObjectLiteral, Repository } from 'typeorm';

/**
 * SoftDeleteService — Phase 1 stub.
 *
 * Wraps TypeORM repository operations to automatically apply a
 * `deleted_at IS NULL` filter, so soft-deleted rows are invisible
 * to all queries by default.
 *
 * Soft delete writes `deleted_at = NOW()` instead of executing DELETE.
 * Hard delete is not exposed.
 */
@Injectable()
export class SoftDeleteService {
  private readonly logger = new Logger(SoftDeleteService.name);

  wrap<T extends ObjectLiteral>(_repository: Repository<T>): Repository<T> {
    this.logger.warn(
      '[STUB] SoftDeleteService.wrap() — returning original repository without soft-delete filter',
    );
    return _repository;
  }

  async softDelete<T extends ObjectLiteral>(
    repository: Repository<T>,
    criteria: Record<string, unknown>,
  ): Promise<void> {
    this.logger.log(
      `[STUB] softDelete on ${repository.metadata.tableName} criteria=${JSON.stringify(criteria)}`,
    );
  }

  async restore<T extends ObjectLiteral>(
    repository: Repository<T>,
    criteria: Record<string, unknown>,
  ): Promise<void> {
    this.logger.log(
      `[STUB] restore on ${repository.metadata.tableName} criteria=${JSON.stringify(criteria)}`,
    );
  }
}
