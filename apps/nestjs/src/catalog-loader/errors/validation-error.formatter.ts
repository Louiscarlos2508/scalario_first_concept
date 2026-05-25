import { z } from 'zod';

export interface ValidationError {
  path: string;
  message: string;
  code: string;
  received?: unknown;
}

export type ValidationErrorList = ValidationError[];

/* eslint-disable @typescript-eslint/no-explicit-any */
const FR_MESSAGES: Record<string, (issue: z.ZodIssue) => string> = {
  invalid_type: (i) => {
    const raw = i as any;
    const expectedType = raw.expected ?? 'unknown';
    const receivedVal = raw.received ?? 'absent';
    const fr: Record<string, string> = {
      string: 'chaîne',
      number: 'nombre',
      boolean: 'booléen',
      object: 'objet',
      array: 'tableau',
    };
    return `doit être de type ${fr[expectedType] ?? expectedType}. Reçu : ${receivedVal}.`;
  },
  too_small: (i) => {
    const raw = i as any;
    const min = raw.minimum;
    const kind = raw.type === 'array' ? 'élément(s)' : 'caractère(s)';
    return `doit contenir au moins ${min} ${kind}.`;
  },
  too_big: (i) => {
    const raw = i as any;
    const max = raw.maximum;
    const kind = raw.type === 'array' ? 'élément(s)' : 'caractère(s)';
    return `doit contenir au plus ${max} ${kind}.`;
  },
  invalid_string: (i) => {
    const raw = i as any;
    if (raw.validation === 'regex') return 'ne respecte pas le format attendu.';
    if (raw.validation === 'email') return 'adresse email invalide.';
    if (raw.validation === 'uuid') return 'identifiant UUID invalide.';
    return 'chaîne invalide.';
  },
  invalid_enum_value: (i) => {
    const raw = i as any;
    const options: string[] = raw.options ?? [];
    const received = raw.received ?? '';
    return `doit être l'une des valeurs : ${options.join(', ')}. Reçu : ${received}.`;
  },
  unrecognized_keys: (i) => {
    const raw = i as any;
    const keys: string[] = raw.keys ?? [];
    return `clé(s) inconnue(s) : ${keys.join(', ')}.`;
  },
  custom: (i) => i.message,
};

export class ValidationErrorFormatter {
  format(error: z.ZodError): ValidationErrorList {
    return error.issues.map((issue) => ({
      path: '.' + issue.path.join('.'),
      message: (FR_MESSAGES[issue.code] ?? ((i) => i.message))(issue),
      code: issue.code,
      received: 'received' in issue ? (issue as any).received : undefined,
    }));
  }
}
