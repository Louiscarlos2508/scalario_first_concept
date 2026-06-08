import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DynamicObjectSchema } from './entities/dynamic-object-schema.entity';
import { DynamicObjectRecord } from './entities/dynamic-object-record.entity';
import { DynamicObjectsService } from './dynamic-objects.service';
import { DynamicObjectsController } from './dynamic-objects.controller';
import { BduiGeneratorService } from './bdui-generator.service';

@Module({
  imports: [TypeOrmModule.forFeature([DynamicObjectSchema, DynamicObjectRecord])],
  controllers: [DynamicObjectsController],
  providers: [DynamicObjectsService, BduiGeneratorService],
  exports: [DynamicObjectsService, BduiGeneratorService],
})
export class DynamicObjectsModule {}
