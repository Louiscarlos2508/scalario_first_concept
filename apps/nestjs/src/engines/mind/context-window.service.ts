import { Injectable, Logger } from '@nestjs/common';

export interface ContextMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

/**
 * ContextWindowService — Phase 1 stub.
 *
 * buildContext(messages, maxTokens) keeps the system prompt intact and
 * preserves the last 3 messages. Older messages beyond that are summarized
 * into a single "context_summary" system message appended after the
 * original system prompt.
 *
 * Tokens are estimated as chars/3 (rough estimator). Phase 2+ will use
 * a proper tokenizer (tiktoken or similar).
 */
@Injectable()
export class ContextWindowService {
  private readonly logger = new Logger(ContextWindowService.name);

  buildContext(messages: ContextMessage[], maxTokens: number): ContextMessage[] {
    this.logger.log(
      `[STUB] buildContext ${messages.length} messages, maxTokens=${maxTokens}`,
    );

    if (messages.length === 0) return [];

    const system = messages.filter((m) => m.role === 'system');
    const nonSystem = messages.filter((m) => m.role !== 'system');

    // Keep last 3 non-system messages
    const recent = nonSystem.slice(-3);
    const older = nonSystem.slice(0, -3);

    const result: ContextMessage[] = [...system];

    if (older.length > 0) {
      const summary = this.summarize(older);
      result.push({ role: 'system', content: summary });
      this.logger.log(`[STUB] summarized ${older.length} older messages`);
    }

    result.push(...recent);

    const estimatedTokens = this.estimateTokens(result);
    this.logger.log(
      `[STUB] final context: ${result.length} messages, ~${estimatedTokens} tokens`,
    );

    return result;
  }

  private summarize(messages: ContextMessage[]): string {
    const content = messages.map((m) => `[${m.role}]: ${m.content.slice(0, 100)}`).join('; ');
    return `[context_summary] ${content}`;
  }

  private estimateTokens(messages: ContextMessage[]): number {
    const totalChars = messages.reduce((sum, m) => sum + m.content.length, 0);
    return Math.ceil(totalChars / 3);
  }
}
