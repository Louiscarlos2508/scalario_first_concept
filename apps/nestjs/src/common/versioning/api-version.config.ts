import { INestApplication, VersioningType } from '@nestjs/common';

/**
 * configureVersioning — Phase 1.
 *
 * Enables header-based API versioning:
 *   X-Scalario-Version: 1
 *
 * Call in main.ts bootstrap() before app.listen():
 *   configureVersioning(app);
 */
export function configureVersioning(app: INestApplication): void {
  app.enableVersioning({
    type: VersioningType.HEADER,
    header: 'X-Scalario-Version',
    defaultVersion: '1',
  });
}
