import { Injectable, Logger } from '@nestjs/common';
import { PRIMITIVES } from './primitives';
import type { AlgoPrimitive } from './primitives';

export interface AlgoFormula {
  fn: string;
  args: (AlgoFormula | number | string | boolean | any[] | Record<string, unknown>)[];
}

export interface EvalOptions {
  debug?: boolean;
}

export interface EvalStep {
  fn: string;
  args: unknown[];
  result: unknown;
}

export interface EvalResult {
  value: unknown;
  type: string;
  steps?: EvalStep[];
}

const MAX_DEPTH = 100;

@Injectable()
export class AlgoEngineService {
  private readonly logger = new Logger(AlgoEngineService.name);
  private steps: EvalStep[] = [];
  private depth = 0;

  eval(
    formula: AlgoFormula | number | string | boolean | any[] | Record<string, unknown>,
    inputs: Record<string, unknown>,
    opts?: EvalOptions,
  ): EvalResult {
    this.steps = [];
    this.depth = 0;
    const value = this.evalRecursive(formula, inputs, opts);
    const type = typeof value;
    if (opts?.debug) {
      return { value, type, steps: [...this.steps] };
    }
    return { value, type };
  }

  private evalRecursive(
    formula: AlgoFormula | number | string | boolean | any[] | Record<string, unknown>,
    inputs: Record<string, unknown>,
    opts?: EvalOptions,
  ): unknown {
    this.depth++;
    if (this.depth > MAX_DEPTH) {
      throw new Error(`Max evaluation depth ${MAX_DEPTH} exceeded`);
    }

    if (typeof formula === 'string' && formula.startsWith('$')) {
      const varName = formula.slice(1);
      const val = inputs[varName];
      if (val === undefined) {
        throw new Error(`Variable not found: $${varName}`);
      }
      return val;
    }

    if (!this.isFormula(formula)) {
      return formula;
    }

    const primitive: AlgoPrimitive | undefined = PRIMITIVES[formula.fn];
    if (!primitive) {
      throw new Error(`Unknown function: ${formula.fn}`);
    }

    const args = ((formula as AlgoFormula).args ?? []).map((arg: any) =>
      this.evalRecursive(arg, inputs, opts),
    );

    const parsed = primitive.schema.safeParse(args);
    if (!parsed.success) {
      throw new Error(
        `Invalid args for ${formula.fn}: ${parsed.error.issues.map((i) => i.message).join('; ')}`,
      );
    }

    try {
      const result = primitive.fn(...(parsed.data as any[]));
      if (opts?.debug) {
        this.steps.push({ fn: formula.fn, args, result });
      }
      return result;
    } catch (err) {
      throw new Error(
        `${(err as Error).message} at step ${this.steps.length} of ${formula.fn}`,
      );
    }
  }

  validate(formula: Record<string, unknown>): boolean {
    try {
      const result = this.eval(formula as unknown as AlgoFormula, {});
      return result.value !== undefined || result.value === null;
    } catch {
      return false;
    }
  }

  private isFormula(val: unknown): val is AlgoFormula {
    return typeof val === 'object' && val !== null && 'fn' in val;
  }
}
