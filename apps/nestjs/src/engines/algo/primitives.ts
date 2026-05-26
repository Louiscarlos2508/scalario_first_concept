import { z } from 'zod';

export interface AlgoPrimitive {
  name: string;
  fn: (...args: any[]) => any;
  schema: z.ZodTypeAny;
}

export const PRIMITIVES: Record<string, AlgoPrimitive> = {
  // --- Math (10) ---
  add: {
    name: 'add',
    fn: (a: number, b: number) => a + b,
    schema: z.tuple([z.number(), z.number()]),
  },
  sub: {
    name: 'sub',
    fn: (a: number, b: number) => a - b,
    schema: z.tuple([z.number(), z.number()]),
  },
  mul: {
    name: 'mul',
    fn: (a: number, b: number) => a * b,
    schema: z.tuple([z.number(), z.number()]),
  },
  div: {
    name: 'div',
    fn: (a: number, b: number) => {
      if (b === 0) throw new Error('div/0');
      return a / b;
    },
    schema: z.tuple([z.number(), z.number()]),
  },
  round: {
    name: 'round',
    fn: (a: number, decimals?: number) => {
      const d = decimals ?? 0;
      return Number(Math.round(Number(a + 'e' + d)) + 'e-' + d);
    },
    schema: z.tuple([z.number(), z.number().optional()]),
  },
  floor: {
    name: 'floor',
    fn: (a: number) => Math.floor(a),
    schema: z.tuple([z.number()]),
  },
  ceil: {
    name: 'ceil',
    fn: (a: number) => Math.ceil(a),
    schema: z.tuple([z.number()]),
  },
  abs: {
    name: 'abs',
    fn: (a: number) => Math.abs(a),
    schema: z.tuple([z.number()]),
  },
  min: {
    name: 'min',
    fn: (a: number, b: number) => Math.min(a, b),
    schema: z.tuple([z.number(), z.number()]),
  },
  max: {
    name: 'max',
    fn: (a: number, b: number) => Math.max(a, b),
    schema: z.tuple([z.number(), z.number()]),
  },

  // --- Logic (10) ---
  if: {
    name: 'if',
    fn: (condition: boolean, thenVal: unknown, elseVal: unknown) =>
      condition ? thenVal : elseVal,
    schema: z.tuple([z.boolean(), z.unknown(), z.unknown()]),
  },
  gt: {
    name: 'gt',
    fn: (a: number, b: number) => a > b,
    schema: z.tuple([z.number(), z.number()]),
  },
  lt: {
    name: 'lt',
    fn: (a: number, b: number) => a < b,
    schema: z.tuple([z.number(), z.number()]),
  },
  eq: {
    name: 'eq',
    fn: (a: unknown, b: unknown) => a === b,
    schema: z.tuple([z.unknown(), z.unknown()]),
  },
  ne: {
    name: 'ne',
    fn: (a: unknown, b: unknown) => a !== b,
    schema: z.tuple([z.unknown(), z.unknown()]),
  },
  gte: {
    name: 'gte',
    fn: (a: number, b: number) => a >= b,
    schema: z.tuple([z.number(), z.number()]),
  },
  lte: {
    name: 'lte',
    fn: (a: number, b: number) => a <= b,
    schema: z.tuple([z.number(), z.number()]),
  },
  and: {
    name: 'and',
    fn: (a: boolean, b: boolean) => a && b,
    schema: z.tuple([z.boolean(), z.boolean()]),
  },
  or: {
    name: 'or',
    fn: (a: boolean, b: boolean) => a || b,
    schema: z.tuple([z.boolean(), z.boolean()]),
  },
  not: {
    name: 'not',
    fn: (a: boolean) => !a,
    schema: z.tuple([z.boolean()]),
  },

  // --- Lists (6) ---
  sum: {
    name: 'sum',
    fn: (arr: number[]) => arr.reduce((a, b) => a + b, 0),
    schema: z.tuple([z.array(z.number())]),
  },
  avg: {
    name: 'avg',
    fn: (arr: number[]) =>
      arr.length === 0 ? null : arr.reduce((a, b) => a + b, 0) / arr.length,
    schema: z.tuple([z.array(z.number())]),
  },
  count: {
    name: 'count',
    fn: (arr: unknown[]) => arr.length,
    schema: z.tuple([z.array(z.unknown())]),
  },
  filter: {
    name: 'filter',
    fn: (arr: Record<string, unknown>[], field: string, value: unknown) =>
      arr.filter((item) => item[field] === value),
    schema: z.tuple([z.array(z.record(z.unknown())), z.string(), z.unknown()]),
  },
  map_field: {
    name: 'map_field',
    fn: (arr: Record<string, unknown>[], field: string) =>
      arr.map((item) => item[field]),
    schema: z.tuple([z.array(z.record(z.unknown())), z.string()]),
  },
  unique: {
    name: 'unique',
    fn: (arr: unknown[]) => [...new Set(arr)],
    schema: z.tuple([z.array(z.unknown())]),
  },

  // --- Dates (4) ---
  today: {
    name: 'today',
    fn: () => new Date().toISOString().split('T')[0],
    schema: z.tuple([]),
  },
  diff_jours: {
    name: 'diff_jours',
    fn: (d1: string, d2: string) => {
      const diff = new Date(d1).getTime() - new Date(d2).getTime();
      return Math.round(diff / (1000 * 60 * 60 * 24));
    },
    schema: z.tuple([z.string(), z.string()]),
  },
  add_days: {
    name: 'add_days',
    fn: (date: string, days: number) => {
      const d = new Date(date);
      d.setDate(d.getDate() + days);
      return d.toISOString().split('T')[0];
    },
    schema: z.tuple([z.string(), z.number()]),
  },
  format_date: {
    name: 'format_date',
    fn: (date: string, format: string) => {
      const d = new Date(date);
      if (format === 'DD/MM/YYYY') {
        return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
      }
      return d.toISOString().split('T')[0];
    },
    schema: z.tuple([z.string(), z.string()]),
  },

  // --- Text (5) ---
  concat: {
    name: 'concat',
    fn: (...args: string[]) => args.join(''),
    schema: z.array(z.string()),
  },
  upper: {
    name: 'upper',
    fn: (s: string) => s.toUpperCase(),
    schema: z.tuple([z.string()]),
  },
  lower: {
    name: 'lower',
    fn: (s: string) => s.toLowerCase(),
    schema: z.tuple([z.string()]),
  },
  format_currency: {
    name: 'format_currency',
    fn: (amount: number, currency: string) => {
      const symbols: Record<string, string> = {
        XOF: 'FCFA', XAF: 'FCFA', EUR: '€', USD: '$', GBP: '£',
        NGN: '₦', GHS: '₵',
      };
      const sym = symbols[currency] ?? currency;
      return `${amount.toLocaleString('fr-FR')} ${sym}`;
    },
    schema: z.tuple([z.number(), z.string()]),
  },
  slugify: {
    name: 'slugify',
    fn: (s: string) =>
      s
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, ''),
    schema: z.tuple([z.string()]),
  },
};
