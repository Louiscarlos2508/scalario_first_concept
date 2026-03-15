import { SetMetadata } from '@nestjs/common';

export const REQUIRES_MODULE_KEY = 'requires_module';

export const RequiresModule = (moduleCode: string) =>
  SetMetadata(REQUIRES_MODULE_KEY, moduleCode);
