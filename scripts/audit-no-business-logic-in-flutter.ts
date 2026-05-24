#!/usr/bin/env -S npx tsx
/**
 * STORY-043 AC-01/AC-02 — auditor that fails CI when Flutter feature
 * code contains hardcoded business / sector / role literals.
 *
 * Whitelist:
 *   - lib/core/**, lib/bdui/**            : engine glue is allowed to reference these names
 *   - *.g.dart                            : generated code
 *   - lines with `// bdui-engine: <why>`  : explicit exception
 *
 * Forbidden patterns inside lib/features/** and lib/screens/**:
 *   - 'OWNER', 'MANAGER', 'COMMERCIAL'    (role literals)
 *   - 'module_'                           (module_id literals)
 *   - 'fresh_produce', 'retail_'          (sector literals)
 *   - 'cloture', 'arrivage', 'perte', 'caisse'  (Blandine domain)
 *
 * Exit code 0 if clean, 1 otherwise.
 */
import { readFileSync } from 'node:fs';
import { resolve, sep } from 'node:path';
import { globSync } from 'node:fs';

interface Violation {
  file: string;
  line: number;
  text: string;
  pattern: string;
}

const REPO_ROOT = resolve(__dirname, '..');
const SCAN_DIRS = ['apps/flutter/lib/features', 'apps/flutter/lib/screens'];
const FORBIDDEN_PATTERNS: Array<{ pattern: RegExp; label: string }> = [
  // Role literals as strings.
  { pattern: /['"](OWNER|MANAGER|COMMERCIAL|SUPER_ADMIN)['"]/, label: 'role-literal' },
  // Module id literals.
  { pattern: /['"]module_[a-z_]+['"]/, label: 'module-id-literal' },
  // Sector/domain.
  { pattern: /['"](retail_|fresh_produce|pharmacy_|btp_)/, label: 'sector-literal' },
  // Blandine-domain business words.
  { pattern: /\b(cloture|arrivage|perte|caisse)\b/i, label: 'business-domain-word' },
];

function isWhitelisted(line: string): boolean {
  return /\/\/\s*bdui-engine\s*:/.test(line);
}

function findDartFiles(): string[] {
  const files: string[] = [];
  for (const dir of SCAN_DIRS) {
    const absDir = resolve(REPO_ROOT, dir);
    try {
      const matches = globSync('**/*.dart', { cwd: absDir });
      for (const m of matches) {
        if (m.endsWith('.g.dart')) continue;
        files.push(resolve(absDir, m));
      }
    } catch {
      // Directory may not exist yet — that's fine.
    }
  }
  return files;
}

function audit(): Violation[] {
  const violations: Violation[] = [];
  for (const file of findDartFiles()) {
    let content: string;
    try {
      content = readFileSync(file, 'utf8');
    } catch {
      continue;
    }
    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (isWhitelisted(line)) continue;
      for (const { pattern, label } of FORBIDDEN_PATTERNS) {
        if (pattern.test(line)) {
          violations.push({
            file: file.replace(REPO_ROOT + sep, ''),
            line: i + 1,
            text: line.trim().slice(0, 120),
            pattern: label,
          });
        }
      }
    }
  }
  return violations;
}

function main(): number {
  const violations = audit();
  if (violations.length === 0) {
    // eslint-disable-next-line no-console
    console.log('✓ No business logic detected in apps/flutter/lib/features|screens.');
    return 0;
  }
  // eslint-disable-next-line no-console
  console.error(
    `✗ Found ${violations.length} violation(s) — Flutter feature code must stay sector-agnostic:`,
  );
  for (const v of violations) {
    // eslint-disable-next-line no-console
    console.error(`  ${v.file}:${v.line}  [${v.pattern}]  ${v.text}`);
  }
  // eslint-disable-next-line no-console
  console.error(
    '\nAdd `// bdui-engine: <reason>` on the line if this is an intentional engine reference,',
  );
  // eslint-disable-next-line no-console
  console.error('or move the logic to lib/core/ or lib/bdui/.');
  return 1;
}

// Run only when invoked directly (allows import for testing).
if (require.main === module) {
  process.exit(main());
}

export { audit, main, FORBIDDEN_PATTERNS };
