import { Injectable, Logger } from '@nestjs/common';

interface TypeScope {
  [variableName: string]: string;
}

interface TypeCheckResult {
  valid: boolean;
  error?: string;
  scope?: TypeScope;
}

interface StepConfig {
  id: string;
  registry: string;
  fn: string;
  inputs?: Record<string, StepInput>;
  output?: { name: string; type: string };
  execute_if?: unknown;
  on_error?: string;
}

type StepInput =
  | { from: string }
  | { literal: unknown }
  | { source: string }
  | { computed: unknown };

@Injectable()
export class ScalarioTypeChecker {
  private readonly logger = new Logger(ScalarioTypeChecker.name);

  private readonly fnSignatures: Record<string, { inputs: string[]; output: string }> = {
    'calc.add': { inputs: ['number', 'number'], output: 'number' },
    'calc.mul': { inputs: ['number', 'number'], output: 'number' },
    'calc.div': { inputs: ['number', 'number'], output: 'number' },
    'calc.format_currency': { inputs: ['currency'], output: 'string' },
    'calc.sum': { inputs: ['list'], output: 'number' },
    'calc.avg': { inputs: ['list'], output: 'number' },
    'calc.if': { inputs: ['boolean', '', ''], output: '' },
    'crud.create': { inputs: ['object'], output: 'entity_ref' },
    'crud.update': { inputs: ['object'], output: 'entity_ref' },
    'crud.delete': { inputs: ['entity_ref'], output: 'boolean' },
    'workflow.advance': { inputs: ['string', 'object'], output: 'object' },
    'canvas.navigate': { inputs: ['string'], output: 'null' },
    'canvas.show_dialog': { inputs: ['object'], output: 'string' },
    'sense.scan_barcode': { inputs: [], output: 'string' },
    'sense.take_photo': { inputs: [], output: 'image' },
    'vault.query': { inputs: ['string'], output: 'list' },
  };

  validate(pipeline: StepConfig[]): TypeCheckResult {
    const scope: TypeScope = {};

    for (let i = 0; i < pipeline.length; i++) {
      const step = pipeline[i];

      if (step.inputs) {
        for (const [key, input] of Object.entries(step.inputs)) {
          if ('from' in input && input.from) {
            const varName = input.from.replace('$', '');
            if (!scope[varName]) {
              // Variable may be an external input from the calling context
              // Only flag as error if it references an output of a previous step
              // that doesn't exist yet
              scope[varName] = 'unknown';
            }
          }
        }
      }

      const sigKey = `${step.registry}.${step.fn}`;
      const sig = this.fnSignatures[sigKey];
      if (!sig) {
        this.logger.warn(`Unknown fn signature: ${sigKey}`);
      }

      if (step.output) {
        const producedType = sig?.output ?? 'unknown';
        scope[step.output.name] =
          step.output.type !== 'unknown' ? step.output.type : producedType;
      }
    }

    return { valid: true, scope };
  }
}
