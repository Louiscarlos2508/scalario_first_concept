import { Injectable, Logger } from '@nestjs/common';
import { readFileSync } from 'fs';
import { join } from 'path';
import type { EngineType } from '../shared/engine-core';

export interface PromptContext {
  screen?: string;
  data?: Record<string, unknown>;
  previousMessages?: string[];
  engine?: EngineType;
}

const UI_SYSTEM_PROMPT = `You are Scalario AI, an expert ERP screen generator for a business management platform used in French-speaking Africa.

Your role is to generate valid A2UI v0.9 protocol messages that the Scalario canvas renders into business screens.

## Rules

1. Always output valid JSON. No markdown, no code fences, no commentary.
2. Prefer data bindings ({ "path": "/data/field" }) over hardcoded values for dynamic data.
3. Use "id": "root" for the top-level container.
4. Reference children by their string IDs in the "children" array.
5. Use variants appropriately (compact, hero, with-icon, etc.) for visual hierarchy.
6. A screen should have a clear visual structure: KPIs at top, main content below, actions accessible.
7. For lists/tables of business data, paginate with page_size: 20.
8. French language for all labels, titles, and messages.

## Protocol Messages

### createSurface — always send first
Creates a rendering surface with an empty data model.
{"version":"v0.9","createSurface":{"surfaceId":"...","catalogId":"scalario-v1"}}

### updateComponents
Replaces all components on a surface. Flat list with ID references.
{"version":"v0.9","updateComponents":{"surfaceId":"...","components":[...]}}

### updateDataModel
Pushes data into the model accessible by path.
{"version":"v0.9","updateDataModel":{"surfaceId":"...","path":"/data","value":{...}}}`;

const FLOW_SYSTEM_PROMPT = `You are Scalario AI, an expert business process composer for an ERP platform.

Your role is to generate valid Flow Engine AST that the Scalario Flow Runtime executes.

## Rules

1. Always output valid JSON. No markdown, no code fences, no commentary.
2. Use data path expressions ("/data/field") to reference runtime data.
3. Every step must have a unique "id".
4. Flow must have exactly one "flow_meta" node with flowId, name, and trigger.
5. Steps reference each other by ID in "then", "else", "on_approved", "on_rejected", etc.

## AST Format

{
  "version": "v0.9",
  "engine": "flow",
  "flow": {
    "id": "flow_id",
    "name": "Flow Name",
    "trigger": { "type": "manual" },
    "steps": [
      { "id": "flow_meta", "type": "flow_meta", "flowId": "...", "name": "...", "triggerType": "manual" },
      { "id": "s1", "type": "condition", "expression": "/data/amount > 1000000", "then": ["s2"], "else": ["s3"] },
      { "id": "s2", "type": "approval", "role": "dg", "message": "Approve this order", "on_approved": ["s4"], "on_rejected": ["s5"] }
    ]
  }
}`;

@Injectable()
export class PromptBuilderService {
  private readonly logger = new Logger(PromptBuilderService.name);
  private uiCatalog: string | null = null;
  private uiExamples: string | null = null;
  private flowCatalog: string | null = null;

  getSystemPrompt(engine: EngineType = 'ui'): string {
    switch (engine) {
      case 'flow':
        return `${FLOW_SYSTEM_PROMPT}\n\n## Flow Primitives Catalog\n${this.loadFlowCatalog()}`;
      case 'ui':
      default:
        return `${UI_SYSTEM_PROMPT}\n\n## Component Catalog\n${this.loadUiCatalog()}\n\n## Examples\n${this.loadUiExamples()}`;
    }
  }

  buildUserPrompt(intent: string, context?: PromptContext): string {
    const parts: string[] = [];

    if (context?.screen) {
      parts.push(`## Screen\n${context.screen}`);
    }

    parts.push(`## User Request\n${intent}`);

    if (context?.data) {
      parts.push(`## Available Data\n\`\`\`json\n${JSON.stringify(context.data, null, 2)}\n\`\`\``);
    }

    if (context?.previousMessages?.length) {
      parts.push('## Previous Errors to Fix');
      for (const msg of context.previousMessages.slice(-3)) {
        parts.push(`- ${msg}`);
      }
    }

    return parts.join('\n\n');
  }

  buildFeedbackPrompt(error: string, previousAttempt: string, engine: EngineType = 'ui'): string {
    const engineName = engine === 'flow' ? 'Flow AST' : 'A2UI';
    return [
      '## Correction Required',
      `The previous output had validation errors:`,
      '',
      error,
      '',
      `Previous output:`,
      previousAttempt,
      '',
      `Please fix the errors and generate a corrected ${engineName} response. Ensure all required fields are present and valid.`,
    ].join('\n');
  }

  private loadUiCatalog(): string {
    if (this.uiCatalog) return this.uiCatalog;

    for (const path of this.uiCandidatePaths()) {
      try {
        const raw = readFileSync(path, 'utf-8');
        const parsed = JSON.parse(raw);
        this.uiCatalog = JSON.stringify(parsed.$defs.ComponentSchemas, null, 2);
        return this.uiCatalog!;
      } catch {
        continue;
      }
    }

    this.logger.warn('Scalario UI Catalog not found — prompts will lack component schemas');
    return 'Catalog not available. Use only: KPICard, StatCard, ChartBar, ChartPie, DataTable, Text, Button, Row, Column, Grid, AlertBanner, FormSection.';
  }

  private loadUiExamples(): string {
    if (this.uiExamples) return this.uiExamples;

    for (const path of this.uiCandidatePaths()) {
      try {
        const raw = readFileSync(path, 'utf-8');
        const parsed = JSON.parse(raw);
        this.uiExamples = JSON.stringify(parsed.examples, null, 2);
        return this.uiExamples!;
      } catch {
        continue;
      }
    }

    return 'No examples available.';
  }

  private loadFlowCatalog(): string {
    if (this.flowCatalog) return this.flowCatalog;

    for (const path of this.flowCandidatePaths()) {
      try {
        const raw = readFileSync(path, 'utf-8');
        const parsed = JSON.parse(raw);
        this.flowCatalog = JSON.stringify(parsed.primitives, null, 2);
        return this.flowCatalog!;
      } catch {
        continue;
      }
    }

    this.logger.warn('Flow Catalog not found');
    return 'Primitives: condition, delay, approval, notify, loop, assign, webhook, end.';
  }

  private uiCandidatePaths(): string[] {
    return [
      join(__dirname, '..', '..', '..', 'assets', 'scalario_catalog.json'),
      join(process.cwd(), 'assets', 'scalario_catalog.json'),
    ];
  }

  private flowCandidatePaths(): string[] {
    return [
      join(__dirname, '..', '..', '..', 'assets', 'flow_catalog.json'),
      join(process.cwd(), 'assets', 'flow_catalog.json'),
    ];
  }
}
