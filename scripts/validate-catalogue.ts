#!/usr/bin/env npx ts-node
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, extname, resolve } from 'node:path';

import { ModuleConfigZod } from '../apps/nestjs/src/catalogue/validators/module-config.zod';
import { ScreenConfigZod } from '../apps/nestjs/src/catalogue/validators/screen-config.zod';
import { WorkflowDefinitionZod } from '../apps/nestjs/src/catalogue/validators/workflow.zod';
import { ComponentConfigZod } from '../apps/nestjs/src/catalogue/validators/component-config.zod';
import { ValidationErrorFormatter } from '../apps/nestjs/src/catalogue/errors/validation-error.formatter';
import { WorkflowValidatorService } from '../apps/nestjs/src/workflow/validator/workflow-validator.service';
import type { ZodTypeAny } from 'zod';

const ROOT = resolve(__dirname, '..');
const CATALOG_DIR = process.env.CATALOG_DIR ?? join(ROOT, 'catalog');

const formatter = new ValidationErrorFormatter();
const dagValidator = new WorkflowValidatorService();

type CatalogueType = 'domain' | 'module' | 'fusion' | 'screen' | 'workflow';
const SCHEMA_MAP: Record<string, ZodTypeAny> = {
  domain: ModuleConfigZod,
  module: ModuleConfigZod,
  fusion: ModuleConfigZod,
  screen: ScreenConfigZod,
  workflow: WorkflowDefinitionZod,
};

let totalFiles = 0;
let validFiles = 0;
let invalidFiles = 0;
const failures: { file: string; errors: string[] }[] = [];

function listJsonFiles(dir: string): string[] {
  const results: string[] = [];
  if (!existsSync(dir)) return results;

  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...listJsonFiles(fullPath));
    } else if (extname(entry.name) === '.json') {
      results.push(fullPath);
    }
  }
  return results;
}

function validateWorkflowDags(parsed: Record<string, unknown>, filePath: string): boolean {
  const workflows = parsed.workflows as Record<string, { id?: string; steps?: Record<string, { id: string; type: string; dependsOn?: string[] }> }> | undefined;
  if (!workflows) return true;

  let allValid = true;
  for (const [wfKey, wf] of Object.entries(workflows)) {
    const wfId = wf.id ?? wfKey;
    const stepValues = wf.steps ? Object.values(wf.steps) : [];
    if (stepValues.length === 0) continue;

    const dagResult = dagValidator.validateDAG(wfId, stepValues.map((s) => ({
      id: s.id,
      type: s.type as 'action' | 'condition' | 'notification' | 'approval',
      dependsOn: s.dependsOn,
    })));

    if (!dagResult.valid) {
      allValid = false;
      for (const err of dagResult.errors) {
        const msg = `workflow.${wfId}: [${err.code}] ${err.message}`;
        console.error(`     └─ ${msg}`);
        failures.push({ file: filePath, errors: [msg] });
      }
    }
  }
  return allValid;
}

function validateFile(filePath: string, type: CatalogueType): void {
  totalFiles++;
  const schema = SCHEMA_MAP[type];
  if (!schema) {
    console.error(`  ❌ ${filePath} — Unknown type: ${type}`);
    failures.push({ file: filePath, errors: [`Unknown type: ${type}`] });
    invalidFiles++;
    return;
  }

  let raw: string;
  try {
    raw = readFileSync(filePath, 'utf8');
  } catch (err) {
    console.error(`  ❌ ${filePath} — Cannot read file: ${(err as Error).message}`);
    failures.push({ file: filePath, errors: [(err as Error).message] });
    invalidFiles++;
    return;
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    const msg = (err as Error).message;
    console.error(`  ❌ ${filePath}`);
    console.error(`     └─ JSON syntaxe invalide: ${msg}`);
    failures.push({ file: filePath, errors: [`JSON syntaxe invalide: ${msg}`] });
    invalidFiles++;
    return;
  }

  const result = schema.safeParse(parsed);
  if (!result.success) {
    invalidFiles++;
    const errors = formatter.format(result.error);
    console.error(`  ❌ ${filePath}`);
    for (const e of errors) {
      console.error(`     └─ ${e.path}: ${e.message}`);
    }
    failures.push({ file: filePath, errors: errors.map((e) => `${e.path}: ${e.message}`) });
    return;
  }

  const dagOk = validateWorkflowDags(result.data as Record<string, unknown>, filePath);
  if (!dagOk) {
    invalidFiles++;
    console.error(`  ❌ ${filePath} — DAG validation failed`);
    return;
  }

  validFiles++;
  console.log(`  ✅ ${filePath}`);
}

console.log('=== Scalario Catalogue Validation ===\n');
console.log(`Catalog root: ${CATALOG_DIR}\n`);

const dirs: [CatalogueType, string][] = [
  ['domain', join(CATALOG_DIR, 'domains')],
  ['module', join(CATALOG_DIR, 'modules')],
  ['fusion', join(CATALOG_DIR, 'fusions')],
];

for (const [type, dir] of dirs) {
  if (!existsSync(dir)) {
    console.log(`\n⚠️  Directory not found: ${dir} (skipping)`);
    continue;
  }

  console.log(`\n📁 ${type}s (${dir}):`);
  const files = listJsonFiles(dir);
  if (files.length === 0) {
    console.log('  (no JSON files found)');
    continue;
  }

  for (const file of files) {
    validateFile(file, type);
  }
}

console.log('\n=== Results ===\n');
console.log(`  Total:   ${totalFiles}`);
console.log(`  Valid:   ${validFiles}`);
console.log(`  Invalid: ${invalidFiles}`);

if (invalidFiles > 0) {
  console.log('\n❌ Catalogue validation failed. Fix the errors above.\n');
  process.exit(1);
}

console.log('\n✅ All catalogue files are valid!\n');