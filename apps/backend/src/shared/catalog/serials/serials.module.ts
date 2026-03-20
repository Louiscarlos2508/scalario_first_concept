import { DynamicModule, Module } from '@nestjs/common';
import { SerialsService } from './serials.service';
import { SerialsController } from './serials.controller';

@Module({})
export class SerialsModule {
  static register(): DynamicModule {
    return {
      module: SerialsModule,
      providers: [SerialsService],
      controllers: [SerialsController],
      exports: [SerialsService],
    };
  }
}
