import { Module } from '@nestjs/common';
import { MindEngineService } from './mind-engine.service';
import { ContextWindowService } from './context-window.service';
import { PromptBuilderService } from './prompt-builder.service';
import { LlmFallbackService } from './llm-fallback.service';

@Module({
  providers: [
    MindEngineService,
    ContextWindowService,
    PromptBuilderService,
    LlmFallbackService,
  ],
  exports: [MindEngineService],
})
export class MindModule {}
