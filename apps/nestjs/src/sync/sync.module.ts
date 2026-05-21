import { Module } from '@nestjs/common';
import { ModuleEngineModule } from '../module-engine/module-engine.module';
import { SyncController } from './sync.controller';

@Module({
  imports: [ModuleEngineModule],
  controllers: [SyncController],
})
export class SyncModule {}
