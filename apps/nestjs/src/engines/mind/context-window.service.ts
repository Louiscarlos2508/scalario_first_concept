import { Injectable, Logger } from '@nestjs/common';

export interface ContextMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
  tokenCount?: number;
}

export interface ConversationStore {
  surfaceId: string;
  messages: ContextMessage[];
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class ContextWindowService {
  private readonly logger = new Logger(ContextWindowService.name);

  private readonly stores = new Map<string, ConversationStore>();

  private readonly SYSTEM_PROMPT_TOKENS = 2000;
  private readonly MAX_TOKENS = 32000;
  private readonly RESPONSE_TOKENS = 4000;

  private readonly SUMMARY_THRESHOLD = 0.7;

  getOrCreateStore(surfaceId: string): ConversationStore {
    let store = this.stores.get(surfaceId);
    if (!store) {
      store = {
        surfaceId,
        messages: [],
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      this.stores.set(surfaceId, store);
    }
    return store;
  }

  addMessage(surfaceId: string, message: ContextMessage): void {
    const store = this.getOrCreateStore(surfaceId);
    message.tokenCount = this.estimateTokens(message.content);
    store.messages.push(message);
    store.updatedAt = new Date();
  }

  addMessages(surfaceId: string, messages: ContextMessage[]): void {
    for (const msg of messages) {
      this.addMessage(surfaceId, msg);
    }
  }

  prune(surfaceId: string): void {
    const store = this.stores.get(surfaceId);
    if (!store || store.messages.length === 0) return;

    const estimatedTotal = this.estimateContextTokens(store.messages);
    const limit = this.MAX_TOKENS - this.SYSTEM_PROMPT_TOKENS - this.RESPONSE_TOKENS;

    if (estimatedTotal <= limit) return;

    const system = store.messages.filter((m) => m.role === 'system');
    const nonSystem = store.messages.filter((m) => m.role !== 'system');

    const summaryThreshold = Math.floor(nonSystem.length * this.SUMMARY_THRESHOLD);
    const toSummarize = nonSystem.slice(0, summaryThreshold);
    const toKeep = nonSystem.slice(summaryThreshold);

    if (toSummarize.length > 1) {
      const summary = this.buildSummary(toSummarize);
      store.messages = [
        ...system,
        { role: 'system', content: summary },
        ...toKeep,
      ];
      this.logger.log(
        `Pruned ${toSummarize.length} messages into summary for surface=${surfaceId}`,
      );
    }
  }

  buildWindow(surfaceId: string, systemPrompt: string): ContextMessage[] {
    const store = this.getOrCreateStore(surfaceId);
    this.prune(surfaceId);

    const window: ContextMessage[] = [
      { role: 'system', content: systemPrompt },
    ];

    for (const msg of store.messages) {
      if (msg.role === 'system') continue;
      window.push(msg);
    }

    const totalTokens = this.estimateContextTokens(window) + this.RESPONSE_TOKENS;
    if (totalTokens <= this.MAX_TOKENS) return window;

    while (this.estimateContextTokens(window) + this.RESPONSE_TOKENS > this.MAX_TOKENS && window.length > 1) {
      const removed = window.pop();
      if (removed) {
        this.logger.debug(`Dropped message from context window: ${removed.content.slice(0, 50)}`);
      }
    }

    return window;
  }

  clear(surfaceId: string): void {
    this.stores.delete(surfaceId);
    this.logger.log(`Cleared conversation store for surface=${surfaceId}`);
  }

  toPrompt(messages: ContextMessage[]): string {
    return messages.map((m) => {
      switch (m.role) {
        case 'system':
          return `[System]\n${m.content}`;
        case 'user':
          return `[User]\n${m.content}`;
        case 'assistant':
          return `[Assistant]\n${m.content}`;
      }
    }).join('\n\n---\n\n');
  }

  estimateTokens(text: string): number {
    const charCount = text.length;
    const wordCount = text.split(/\s+/).length;
    return Math.max(
      Math.ceil(charCount / 4),
      Math.ceil(wordCount * 1.5),
    );
  }

  private estimateContextTokens(messages: ContextMessage[]): number {
    let total = 0;
    for (const msg of messages) {
      total += msg.tokenCount ?? this.estimateTokens(msg.content);
    }
    return total;
  }

  private buildSummary(messages: ContextMessage[]): string {
    const condensed = messages.map((m) => {
      const preview = m.content.replace(/\s+/g, ' ').slice(0, 150);
      return `[${m.role}]: ${preview}`;
    });

    return `[context_summary] Previous conversation:\n${condensed.join('\n')}`;
  }
}
