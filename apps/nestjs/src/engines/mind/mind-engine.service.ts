import { Injectable, Logger } from '@nestjs/common';
import { ContextWindowService, ContextMessage } from './context-window.service';
import { PromptBuilderService, PromptContext } from './prompt-builder.service';
import { LlmFallbackService, LlmResponse } from './llm-fallback.service';
import type { EngineType } from '../shared/engine-core';

export interface MindEngineRequest {
  surfaceId: string;
  intent: string;
  context?: PromptContext;
  engine?: EngineType;
  maxRetries?: number;
  temperature?: number;
}

export interface MindEngineResponse {
  surfaceId: string;
  text: string;
  model: string;
  degraded: boolean;
  retries: number;
  engine: EngineType;
}

interface ValidationResult {
  valid: boolean;
  errors: string[];
}

@Injectable()
export class MindEngineService {
  private readonly logger = new Logger(MindEngineService.name);

  private readonly MAX_RETRIES = 3;

  constructor(
    private readonly contextWindow: ContextWindowService,
    private readonly promptBuilder: PromptBuilderService,
    private readonly llm: LlmFallbackService,
  ) {}

  async generate(request: MindEngineRequest): Promise<MindEngineResponse> {
    const surfaceId = request.surfaceId;
    const engine = request.engine ?? 'ui';
    const maxRetries = request.maxRetries ?? this.MAX_RETRIES;

    this.logger.log(
      `MindEngine generate: engine=${engine} surface=${surfaceId} intent="${request.intent}"`,
    );

    const systemPrompt = this.promptBuilder.getSystemPrompt(engine);
    const userPrompt = this.promptBuilder.buildUserPrompt(request.intent, request.context);

    this.contextWindow.addMessage(surfaceId, { role: 'user', content: userPrompt });

    let lastResponse: LlmResponse | null = null;
    let retries = 0;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        this.logger.log(`Retry attempt ${attempt}/${maxRetries} for engine=${engine} surface=${surfaceId}`);
      }

      const window = this.contextWindow.buildWindow(surfaceId, systemPrompt);
      const prompt = this.contextWindow.toPrompt(window);

      lastResponse = await this.llm.complete({
        prompt,
        temperature: request.temperature ?? 0.3,
        maxTokens: 4000,
      });

      if (lastResponse.degraded) {
        this.logger.warn(`LLM degraded on attempt ${attempt} for engine=${engine} surface=${surfaceId}`);
        return {
          surfaceId,
          text: '',
          model: 'degraded',
          degraded: true,
          retries: attempt,
          engine,
        };
      }

      this.contextWindow.addMessage(surfaceId, {
        role: 'assistant',
        content: lastResponse.text,
      });

      const validation = this.validateOutput(lastResponse.text, engine);
      if (validation.valid) {
        this.logger.log(`LLM output valid after ${attempt} retries for engine=${engine} surface=${surfaceId}`);
        return {
          surfaceId,
          text: lastResponse.text,
          model: lastResponse.model,
          degraded: false,
          retries: attempt,
          engine,
        };
      }

      this.logger.warn(`Validation failed on attempt ${attempt}: ${validation.errors.join(', ')}`);

      if (attempt < maxRetries) {
        const feedback = this.promptBuilder.buildFeedbackPrompt(
          validation.errors.join('\n'),
          lastResponse.text,
          engine,
        );
        this.contextWindow.addMessage(surfaceId, { role: 'user', content: feedback });
        retries++;
      }
    }

    this.logger.error(`All ${maxRetries} attempts exhausted for engine=${engine} surface=${surfaceId}`);

    return {
      surfaceId,
      text: lastResponse?.text ?? '',
      model: lastResponse?.model ?? 'unknown',
      degraded: true,
      retries,
      engine,
    };
  }

  private validateOutput(text: string, engine: EngineType): ValidationResult {
    switch (engine) {
      case 'flow':
        return this.validateFlowAst(text);
      case 'ui':
      default:
        return this.validateA2uiOutput(text);
    }
  }

  private validateA2uiOutput(text: string): ValidationResult {
    const errors: string[] = [];

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      return { valid: false, errors: ['No JSON object found in LLM response'] };
    }

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(jsonMatch[0]) as Record<string, unknown>;
    } catch {
      return { valid: false, errors: ['Response is not valid JSON'] };
    }

    if (!parsed.version || parsed.version !== 'v0.9') {
      errors.push('Missing or invalid version field (must be "v0.9")');
    }

    if (parsed.createSurface) {
      const cs = parsed.createSurface as Record<string, unknown>;
      if (!cs.surfaceId) errors.push('createSurface: missing surfaceId');
      if (!cs.catalogId) errors.push('createSurface: missing catalogId');
    }

    if (parsed.updateComponents) {
      const uc = parsed.updateComponents as Record<string, unknown>;
      if (!uc.surfaceId) errors.push('updateComponents: missing surfaceId');

      const components = uc.components as Array<Record<string, unknown>> | undefined;
      if (!components || !Array.isArray(components)) {
        errors.push('updateComponents: components must be an array');
      } else {
        const ids = new Set<string>();
        for (let i = 0; i < components.length; i++) {
          const c = components[i];
          if (!c.id) {
            errors.push(`components[${i}]: missing id`);
          } else {
            if (ids.has(c.id as string)) {
              errors.push(`Duplicate component id: ${c.id}`);
            }
            ids.add(c.id as string);
          }
          if (!c.component) {
            errors.push(`components[${i}] (id=${c.id}): missing component type`);
          }
        }

        const root = components.find((c) => c.id === 'root');
        if (!root) {
          errors.push('No root component found (id="root" is recommended)');
        }
      }
    }

    if (parsed.updateDataModel) {
      const dm = parsed.updateDataModel as Record<string, unknown>;
      if (!dm.surfaceId) errors.push('updateDataModel: missing surfaceId');
    }

    return { valid: errors.length === 0, errors };
  }

  private validateFlowAst(text: string): ValidationResult {
    const errors: string[] = [];

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      return { valid: false, errors: ['No JSON object found in LLM response'] };
    }

    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(jsonMatch[0]) as Record<string, unknown>;
    } catch {
      return { valid: false, errors: ['Response is not valid JSON'] };
    }

    if (parsed.version !== 'v0.9') {
      errors.push('Missing or invalid version (must be "v0.9")');
    }

    if (parsed.engine !== 'flow') {
      errors.push('engine must be "flow"');
    }

    const flow = parsed.flow as Record<string, unknown> | undefined;
    if (!flow) {
      errors.push('Missing "flow" root object');
      return { valid: false, errors };
    }

    if (!flow.id) errors.push('flow: missing id');
    if (!flow.name) errors.push('flow: missing name');

    const trigger = flow.trigger as Record<string, unknown> | undefined;
    if (!trigger) {
      errors.push('flow: missing trigger');
    } else if (!trigger.type) {
      errors.push('trigger: missing type');
    }

    const steps = flow.steps as Array<Record<string, unknown>> | undefined;
    if (!steps || !Array.isArray(steps)) {
      errors.push('flow.steps must be an array');
      return { valid: errors.length === 0, errors };
    }

    const validTypes = ['flow_meta', 'condition', 'delay', 'approval', 'notify', 'loop', 'assign', 'webhook', 'end'];
    const stepIds = new Set<string>();

    for (let i = 0; i < steps.length; i++) {
      const s = steps[i];

      if (!s.id) {
        errors.push(`steps[${i}]: missing id`);
      } else {
        if (stepIds.has(s.id as string)) {
          errors.push(`Duplicate step id: ${s.id}`);
        }
        stepIds.add(s.id as string);
      }

      if (!s.type) {
        errors.push(`steps[${i}] (id=${s.id}): missing type`);
      } else if (!validTypes.includes(s.type as string)) {
        errors.push(`steps[${i}] (id=${s.id}): invalid type "${s.type}"`);
      }

      if (s.type === 'flow_meta') {
        if (!s.flowId) errors.push(`flow_meta: missing flowId`);
        if (!s.name) errors.push(`flow_meta: missing name`);
      }

      if (s.type === 'condition' && !s.expression) {
        errors.push(`condition ${s.id}: missing expression`);
      }

      if (s.type === 'delay' && s.duration == null) {
        errors.push(`delay ${s.id}: missing duration`);
      }

      if (s.type === 'approval' && !s.role) {
        errors.push(`approval ${s.id}: missing role`);
      }

      if (s.type === 'notify') {
        if (!s.channel) errors.push(`notify ${s.id}: missing channel`);
        if (!s.to) errors.push(`notify ${s.id}: missing to`);
        if (!s.template) errors.push(`notify ${s.id}: missing template`);
      }

      if (s.type === 'webhook' && !s.url) {
        errors.push(`webhook ${s.id}: missing url`);
      }
    }

    const hasMeta = steps.some((s) => s.type === 'flow_meta');
    if (!hasMeta) {
      errors.push('No flow_meta step found');
    }

    return { valid: errors.length === 0, errors };
  }
}
