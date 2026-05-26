import { Injectable, Logger } from '@nestjs/common';

export interface LlmRequest {
  messages: Array<{ role: string; content: string }>;
  maxTokens?: number;
  temperature?: number;
}

export interface LlmResponse {
  content: string;
  model: string;
  fallbackUsed: boolean;
}

/**
 * LlmFallbackService — Phase 1 stub.
 *
 * complete(request) attempts DeepSeek V4, falls back to Claude API on
 * failure, and finally falls back to a degraded mode (local/static reply).
 *
 * Phase 2+ will integrate real HTTP calls to each LLM provider.
 */
@Injectable()
export class LlmFallbackService {
  private readonly logger = new Logger(LlmFallbackService.name);

  async complete(request: LlmRequest): Promise<LlmResponse> {
    this.logger.log(
      `[STUB] complete with ${request.messages.length} messages, maxTokens=${request.maxTokens ?? 'unset'}`,
    );

    try {
      const result = await this.tryDeepSeek(request);
      if (result) return result;
    } catch (err) {
      this.logger.warn(`[STUB] DeepSeek V4 failed: ${(err as Error).message}`);
    }

    try {
      const result = await this.tryClaude(request);
      if (result) return result;
    } catch (err) {
      this.logger.warn(`[STUB] Claude failed: ${(err as Error).message}`);
    }

    return this.degradedMode(request);
  }

  private async tryDeepSeek(request: LlmRequest): Promise<LlmResponse | null> {
    this.logger.log('[STUB] trying DeepSeek V4');
    return null; // Stub: simulate failure, triggers fallback chain
  }

  private async tryClaude(request: LlmRequest): Promise<LlmResponse | null> {
    this.logger.log('[STUB] trying Claude API');
    return null; // Stub: simulate failure, triggers degraded mode
  }

  private degradedMode(request: LlmRequest): LlmResponse {
    const lastMsg = request.messages.at(-1)?.content ?? '';
    this.logger.warn(`[STUB] entering degraded mode for prompt: "${lastMsg.slice(0, 80)}..."`);
    return {
      content: `[degraded] Unable to process request. System is operating in fallback mode.`,
      model: 'degraded',
      fallbackUsed: true,
    };
  }
}
