import { Injectable, Logger } from '@nestjs/common';
import { MindEngineService } from '../../engines/mind/mind-engine.service';
import { ScalarioLiveService } from '../../engines/live/scalario-live.service';
import type { AiRelayRequest, AiRelayResponse } from '../interfaces/ai-relay.interfaces';

@Injectable()
export class AiRelayService {
  private readonly logger = new Logger(AiRelayService.name);

  constructor(
    private readonly mind: MindEngineService,
    private readonly live: ScalarioLiveService,
  ) {}

  async generateScreen(request: AiRelayRequest): Promise<AiRelayResponse> {
    this.logger.log(`Generating screen for surface=${request.surfaceId} intent="${request.intent}"`);

    const result = await this.mind.generate({
      surfaceId: request.surfaceId,
      intent: request.intent,
      context: request.context,
    });

    if (result.degraded) {
      return this.buildDegradedResponse(request.surfaceId);
    }

    return this.parseLlmOutput(request, result.text);
  }

  async generateAndPush(request: AiRelayRequest): Promise<AiRelayResponse> {
    const response = await this.generateScreen(request);

    for (const message of response.messages) {
      this.live.emitToUser(request.userId, {
        type: 'a2ui_message',
        data: message as Record<string, unknown>,
        timestamp: new Date().toISOString(),
      });
    }

    return response;
  }

  private parseLlmOutput(request: AiRelayRequest, raw: string): AiRelayResponse {
    const messages: AiRelayResponse['messages'] = [];
    const surfaceId = request.surfaceId;

    messages.push({
      version: 'v0.9',
      createSurface: {
        surfaceId,
        catalogId: 'scalario-v1',
      },
    });

    try {
      const jsonStart = raw.indexOf('{');
      const jsonEnd = raw.lastIndexOf('}');
      if (jsonStart === -1 || jsonEnd === -1) {
        throw new Error('No JSON found in LLM response');
      }
      const jsonStr = raw.slice(jsonStart, jsonEnd + 1);
      const parsed = JSON.parse(jsonStr);

      const filtered: Record<string, unknown> = {};
      for (const [key, value] of Object.entries(parsed)) {
        if (key === 'updateComponents' || key === 'updateDataModel') {
          filtered[key] = value;
        }
      }

      if (Object.keys(filtered).length > 0) {
        messages.push({ version: 'v0.9', ...filtered });
      }
    } catch (e) {
      this.logger.warn(`Failed to parse LLM JSON: ${(e as Error).message}`);
    }

    return {
      surfaceId,
      messages,
      model: 'deepseek-v4',
      degraded: false,
    };
  }

  private buildDegradedResponse(surfaceId: string): AiRelayResponse {
    const messages: AiRelayResponse['messages'] = [
      {
        version: 'v0.9',
        createSurface: {
          surfaceId,
          catalogId: 'scalario-v1',
        },
      },
      {
        version: 'v0.9',
        updateComponents: {
          surfaceId,
          components: [
            {
              id: 'root',
              component: 'Column',
              children: ['error-banner'],
            },
            {
              id: 'error-banner',
              component: 'AlertBanner',
              type: 'danger',
              message: 'Service temporairement indisponible. Veuillez réessayer.',
            },
          ],
        },
      },
    ];

    return {
      surfaceId,
      messages,
      model: 'degraded',
      degraded: true,
    };
  }
}
