import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { CatalogueValidatorService } from './catalogue-validator.service';

@Injectable()
export class CatalogueLoaderService implements OnApplicationBootstrap {
  private readonly logger = new Logger(CatalogueLoaderService.name);
  private readonly rootDir: string;

  constructor(private readonly validator: CatalogueValidatorService) {
    this.rootDir = process.env.CATALOG_DIR ?? this.resolveCatalogRoot();
  }

  async onApplicationBootstrap(): Promise<void> {
    this.logger.log('Validating catalogue files on bootstrap...');

    const results = this.validator.validateDirectory(this.rootDir);
    const failures = results.filter((r) => !r.valid);
    const loaded = {
      domains: results.filter((r) => r.type === 'domain' && r.valid).length,
      modules: results.filter((r) => r.type === 'module' && r.valid).length,
      fusions: results.filter((r) => r.type === 'fusion' && r.valid).length,
    };

    if (failures.length > 0) {
      for (const f of failures) {
        if (f.parseError) {
          this.logger.error(`catalogue.invalid — ${f.file}: ${f.parseError}`);
        } else if (f.errors) {
          const errorLines = f.errors.map((e) => `  └─ ${e.path}: ${e.message}`).join('\n');
          this.logger.error(`catalogue.invalid — ${f.file}\n${errorLines}`);
        }
      }
      throw new Error(
        `Catalogue invalid : ${failures.length} fichier(s) en erreur. L'application refuse de démarrer.`,
      );
    }

    this.logger.log('catalogue.loaded', loaded);
  }

  private resolveCatalogRoot(): string {
    let dir = process.cwd();
    for (let i = 0; i < 5; i++) {
      if (existsSync(resolve(dir, 'catalog', 'domains'))) {
        return resolve(dir, 'catalog');
      }
      dir = resolve(dir, '..');
    }
    return resolve(process.cwd(), 'catalog');
  }
}
