#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');

const arbDir = path.resolve(__dirname, '../apps/flutter/lib/l10n');
const fr = JSON.parse(fs.readFileSync(path.join(arbDir, 'app_fr.arb'), 'utf8'));
const en = JSON.parse(fs.readFileSync(path.join(arbDir, 'app_en.arb'), 'utf8'));

const frKeys = Object.keys(fr).filter(k => !k.startsWith('@'));
const enKeys = Object.keys(en).filter(k => !k.startsWith('@'));
const enSet = new Set(enKeys);
const missing = frKeys.filter(k => !enSet.has(k));
const coverage = Math.round((enKeys.length / frKeys.length) * 100);

console.log(`i18n Coverage Report:`);
console.log(`  FR keys: ${frKeys.length}`);
console.log(`  EN keys: ${enKeys.length}`);
console.log(`  Coverage: ${coverage}%`);
console.log(`  Missing in EN: ${missing.length}`);
if (missing.length > 0 && missing.length <= 10) {
  console.log(`  Missing keys: ${missing.join(', ')}`);
}
if (coverage < 60) {
  console.log('  WARNING: EN coverage below 60% target');
  process.exit(1);
}
