#!/usr/bin/env node

import { readFileSync, readdirSync, existsSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, '..');
const SCHEMAS_DIR = join(ROOT, 'catalog', 'schemas');
const EXAMPLES_DIR = join(SCHEMAS_DIR, 'examples');

const SCHEMA_FILES = [
  'component-config.schema.json',
  'screen-config.schema.json',
  'module-config.schema.json',
  'workflow.schema.json',
];

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;
const failures = [];

async function main() {
  const Ajv2020 = (await import('ajv/dist/2020.js')).default;
  const addFormats = (await import('ajv-formats')).default;

  const ajv = new Ajv2020({
    strict: false,
    allErrors: true,
  });
  addFormats(ajv);

  console.log('=== Scalario BDUI JSON Schema Validation ===\n');

  console.log('1. Validating schemas (compilation + structure checks)...\n');

  for (const schemaFile of SCHEMA_FILES) {
    const filePath = join(SCHEMAS_DIR, schemaFile);
    const schemaContent = JSON.parse(readFileSync(filePath, 'utf-8'));
    totalTests++;

    if (!schemaContent.$id) {
      failures.push(`FAIL: ${schemaFile} — missing $id`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — missing $id`);
      continue;
    }

    if (!schemaContent.$schema) {
      failures.push(`FAIL: ${schemaFile} — missing $schema`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — missing $schema`);
      continue;
    }

    if (schemaContent.$schema !== 'https://json-schema.org/draft/2020-12/schema') {
      failures.push(`FAIL: ${schemaFile} — $schema must be Draft 2020-12, got: ${schemaContent.$schema}`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — $schema != Draft 2020-12`);
      continue;
    }

    if (!schemaContent.$id.startsWith('https://scalario.io/schemas/v1.0.0/')) {
      failures.push(`FAIL: ${schemaFile} — $id must start with https://scalario.io/schemas/v1.0.0/, got: ${schemaContent.$id}`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — $id invalid: ${schemaContent.$id}`);
      continue;
    }

    try {
      ajv.addSchema(schemaContent, schemaContent.$id);
      passedTests++;
      console.log(`  ✓ ${schemaFile} — valid Draft 2020-12 schema ($id: ${schemaContent.$id})`);
    } catch (err) {
      failures.push(`FAIL: ${schemaFile} — schema compilation error: ${err.message}`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — compilation error: ${err.message}`);
    }
  }

  console.log('\n2. Validating schema_version is const "1.0.0"...\n');

  for (const schemaFile of SCHEMA_FILES) {
    const filePath = join(SCHEMAS_DIR, schemaFile);
    const schemaContent = JSON.parse(readFileSync(filePath, 'utf-8'));
    totalTests++;

    const schemaVersion = schemaContent.properties?.schema_version;
    if (!schemaVersion) {
      failures.push(`FAIL: ${schemaFile} — no schema_version property`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — no schema_version property`);
      continue;
    }

    if (schemaVersion.const !== '1.0.0') {
      failures.push(`FAIL: ${schemaFile} — schema_version.const is "${schemaVersion.const}", expected "1.0.0"`);
      failedTests++;
      console.log(`  ✗ ${schemaFile} — schema_version.const = "${schemaVersion.const}" (expected "1.0.0")`);
      continue;
    }

    passedTests++;
    console.log(`  ✓ ${schemaFile} — schema_version = "1.0.0" (const)`);
  }

  console.log('\n3. Validating examples (valid_*.json should pass)...\n');

  for (const schemaFile of SCHEMA_FILES) {
    const schemaName = schemaFile.replace('.schema.json', '');
    const exampleDir = join(EXAMPLES_DIR, schemaName);
    const schemaContent = JSON.parse(readFileSync(join(SCHEMAS_DIR, schemaFile), 'utf-8'));

    if (!existsSync(exampleDir)) {
      console.log(`  ⚠ No examples directory for ${schemaName}`);
      continue;
    }

    const files = readdirSync(exampleDir).filter(f => f.startsWith('valid') && f.endsWith('.json'));
    if (files.length === 0) {
      console.log(`  ⚠ No valid examples for ${schemaName}`);
      continue;
    }

    for (const exampleFile of files) {
      const examplePath = join(exampleDir, exampleFile);
      const exampleContent = JSON.parse(readFileSync(examplePath, 'utf-8'));
      totalTests++;

      try {
        const validate = ajv.getSchema(schemaContent.$id);
        if (!validate) {
          failures.push(`FAIL: ${schemaName}/${exampleFile} — schema not found in Ajv: ${schemaContent.$id}`);
          failedTests++;
          console.log(`  ✗ ${schemaName}/${exampleFile} — schema not found`);
          continue;
        }
        const valid = validate(exampleContent);

        if (valid) {
          passedTests++;
          console.log(`  ✓ ${schemaName}/${exampleFile} — valid (accepted)`);
        } else {
          const errors = validate.errors?.map(e => `${e.instancePath || '/'} ${e.message}`).join('; ');
          failures.push(`FAIL: ${schemaName}/${exampleFile} — expected valid but rejected: ${errors}`);
          failedTests++;
          console.log(`  ✗ ${schemaName}/${exampleFile} — expected valid but rejected: ${errors}`);
        }
      } catch (err) {
        failures.push(`FAIL: ${schemaName}/${exampleFile} — validation error: ${err.message}`);
        failedTests++;
        console.log(`  ✗ ${schemaName}/${exampleFile} — error: ${err.message}`);
      }
    }
  }

  console.log('\n4. Validating counter-examples (invalid_*.json should be rejected)...\n');

  for (const schemaFile of SCHEMA_FILES) {
    const schemaName = schemaFile.replace('.schema.json', '');
    const exampleDir = join(EXAMPLES_DIR, schemaName);
    const schemaContent = JSON.parse(readFileSync(join(SCHEMAS_DIR, schemaFile), 'utf-8'));

    if (!existsSync(exampleDir)) {
      continue;
    }

    const files = readdirSync(exampleDir).filter(f => f.startsWith('invalid') && f.endsWith('.json'));
    if (files.length === 0) {
      console.log(`  ⚠ No invalid examples for ${schemaName}`);
      continue;
    }

    for (const exampleFile of files) {
      const examplePath = join(exampleDir, exampleFile);
      const exampleContent = JSON.parse(readFileSync(examplePath, 'utf-8'));
      totalTests++;

      try {
        const validate = ajv.getSchema(schemaContent.$id);
        if (!validate) {
          failures.push(`FAIL: ${schemaName}/${exampleFile} — schema not found in Ajv`);
          failedTests++;
          console.log(`  ✗ ${schemaName}/${exampleFile} — schema not found`);
          continue;
        }
        const valid = validate(exampleContent);

        if (!valid) {
          const errors = validate.errors?.map(e => `${e.instancePath || '/'} ${e.message}`).join('; ');
          passedTests++;
          console.log(`  ✓ ${schemaName}/${exampleFile} — correctly rejected: ${errors}`);
        } else {
          failures.push(`FAIL: ${schemaName}/${exampleFile} — expected invalid but was accepted`);
          failedTests++;
          console.log(`  ✗ ${schemaName}/${exampleFile} — expected invalid but was accepted`);
        }
      } catch (err) {
        failures.push(`FAIL: ${schemaName}/${exampleFile} — validation error: ${err.message}`);
        failedTests++;
        console.log(`  ✗ ${schemaName}/${exampleFile} — error: ${err.message}`);
      }
    }
  }

  console.log('\n=== Results ===\n');
  console.log(`  Total:  ${totalTests}`);
  console.log(`  Passed: ${passedTests}`);
  console.log(`  Failed: ${failedTests}`);

  if (failures.length > 0) {
    console.log('\n=== Failures ===\n');
    failures.forEach(f => console.log(`  ${f}`));
  }

  if (failedTests > 0) {
    process.exit(1);
  }

  console.log('\n✅ All schema validations passed!');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});