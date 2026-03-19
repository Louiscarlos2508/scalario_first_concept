import { DynamicModule, Module } from '@nestjs/common';
import { BatchesService } from './batches.service';
import { BatchesController } from './batches.controller';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({})
export class BatchesModule {
  static register(): DynamicModule {
    return {
      module: BatchesModule,
      imports: [PrismaModule],
      controllers: [BatchesController],
      providers: [BatchesService],
      exports: [BatchesService],
    };
  }
}
