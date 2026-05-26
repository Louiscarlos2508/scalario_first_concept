import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';

interface LlmRequest {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
}

interface LlmResponse {
  text: string;
  model: string;
  degraded?: boolean;
}

@Injectable()
export class LlmFallbackService {
  private readonly logger = new Logger(LlmFallbackService.name);

  private readonly deepseekUrl = process.env.DEEPSEEK_URL ?? 'http://localhost:8080/v1/completions';
  private readonly claudeKey = process.env.CLAUDE_API_KEY;

  constructor(private readonly http: HttpService) {}

  async complete(request: LlmRequest): Promise<LlmResponse> {
    try {
      return await this.callDeepSeek(request);
    } catch (e1) {
      this.logger.warn(`DeepSeek unavailable: ${(e1 as Error).message}`);
    }

    if (this.claudeKey) {
      try {
        return await this.callClaude(request);
      } catch (e2) {
        this.logger.warn(`Claude unavailable: ${(e2 as Error).message}`);
      }
    }

    this.logger.warn('All LLMs unavailable — degraded mode');
    return { text: '', model: 'degraded', degraded: true };
  }

  private async callDeepSeek(request: LlmRequest): Promise<LlmResponse> {
    this.logger.log('Calling DeepSeek V4');
    return { text: '[DeepSeek response stub]', model: 'deepseek-v4' };
  }

  private async callClaude(request: LlmRequest): Promise<LlmResponse> {
    this.logger.log('Calling Claude API');
    return { text: '[Claude response stub]', model: 'claude-sonnet' };
  }
}
