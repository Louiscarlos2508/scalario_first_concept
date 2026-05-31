import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MindModule } from '../mind/mind.module';
import { FlowController } from './flow.controller';
import { FlowCompilerService } from './flow-compiler.service';
import { FlowRuntimeService } from './flow-runtime.service';
import { FlowResumeService } from './flow-resume.service';
import { FlowPendingDelay } from './entities/flow-pending-delay.entity';

@Module({
  imports: [MindModule, TypeOrmModule.forFeature([FlowPendingDelay])],
  controllers: [FlowController],
  providers: [FlowCompilerService, FlowRuntimeService, FlowResumeService],
  exports: [FlowCompilerService, FlowRuntimeService, FlowResumeService],
})
export class FlowModule {}
