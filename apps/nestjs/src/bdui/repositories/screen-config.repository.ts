import { InjectRepository } from '@nestjs/typeorm';
import { Injectable, Logger } from '@nestjs/common';
import { Repository } from 'typeorm';
import { ScreenConfigEntity } from '../entities/screen-config.entity';

@Injectable()
export class ScreenConfigRepository {
  private readonly logger = new Logger(ScreenConfigRepository.name);

  constructor(
    @InjectRepository(ScreenConfigEntity)
    private readonly repo: Repository<ScreenConfigEntity>,
  ) {}

  async findByTenantAndScreen(
    tenantId: string,
    screenId: string,
  ): Promise<Record<string, unknown> | null> {
    const row = await this.repo.findOne({
      where: { tenant_id: tenantId, screen_id: screenId, is_active: true },
    });
    if (!row) return null;
    this.logger.debug(`screen_configs DB hit: tenant=${tenantId} screen=${screenId}`);
    return {
      ...row.config,
      schema_version: row.schema_version,
      screen: row.screen_id,
    };
  }
}
