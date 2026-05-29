import { Module } from '@nestjs/common';
import { MindModule } from '../mind/mind.module';
import { FlowController } from './flow.controller';
import { FlowCompilerService } from './flow-compiler.service';
import { FlowRuntimeService } from './flow-runtime.service';

@Module({
  imports: [MindModule],
  controllers: [FlowController],
  providers: [FlowCompilerService, FlowRuntimeService],
  exports: [FlowCompilerService, FlowRuntimeService],
})
export class FlowModule {}
