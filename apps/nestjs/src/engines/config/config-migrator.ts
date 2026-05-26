import { Injectable, Logger } from '@nestjs/common';

interface TenantConfig {
  schema_version: string;
  [k: string]: unknown;
}

type MigrationFn = (config: TenantConfig) => TenantConfig;

interface Migration {
  nextVersion: string;
  up: MigrationFn;
}

@Injectable()
export class ConfigMigrator {
  private readonly logger = new Logger(ConfigMigrator.name);

  private readonly migrations: Record<string, Migration> = {
    '1.0.0': {
      nextVersion: '1.1.0',
      up: (config) => {
        const result = { ...config, schema_version: '1.1.0' };
        return this.deepAddVariant(result);
      },
    },
    '1.1.0': {
      nextVersion: '1.2.0',
      up: (config) => {
        return { ...config, schema_version: '1.2.0' };
      },
    },
  };

  migrate(config: TenantConfig, targetVersion: string): TenantConfig {
    let current = config.schema_version;

    while (current !== targetVersion) {
      const migration = this.migrations[current];
      if (!migration) {
        this.logger.error(`No migration path from ${current}`);
        throw new Error(`No migration from version ${current} to ${targetVersion}`);
      }
      this.logger.log(`Migrating config ${current} → ${migration.nextVersion}`);
      config = migration.up(config);
      current = migration.nextVersion;
    }

    return config;
  }

  private deepAddVariant(obj: unknown): any {
    if (Array.isArray(obj)) return obj.map((item) => this.deepAddVariant(item));
    if (obj && typeof obj === 'object') {
      const result: any = { ...obj };
      if ((result as any).type && !(result as any).variant) {
        result.variant = 'default';
      }
      for (const key of Object.keys(result)) {
        result[key] = this.deepAddVariant(result[key]);
      }
      return result;
    }
    return obj;
  }
}
