#!/usr/bin/env bash
set -euo pipefail

# Build HTML documentation from JSON Schema files
# Usage: ./scripts/build-schema-docs.sh
# Output: docs/bdui-schema/index.html

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMAS_DIR="$ROOT_DIR/catalog/schemas"
OUTPUT_DIR="$ROOT_DIR/docs/bdui-schema"

SCHEMAS=(
  "component-config.schema.json"
  "screen-config.schema.json"
  "module-config.schema.json"
  "workflow.schema.json"
)

mkdir -p "$OUTPUT_DIR"

echo "=== Building BDUI Schema Documentation ==="
echo "Schemas dir: $SCHEMAS_DIR"
echo "Output dir:  $OUTPUT_DIR"
echo ""

# Check if node is available
if ! command -v node &> /dev/null; then
  echo "ERROR: node is required to build schema documentation"
  exit 1
fi

# Generate HTML documentation using a self-contained Node.js script
node -e "
const fs = require('fs');
const path = require('path');

const schemasDir = '$SCHEMAS_DIR';
const outputDir = '$OUTPUT_DIR';
const schemas = [$(printf "'%s'," "${SCHEMAS[@]}")];

// Schema metadata for navigation
const schemaMeta = {
  'component-config.schema.json': { title: 'ComponentConfig', desc: 'Composant BDUI unique — widget DS avec visibilité, source de données, validation' },
  'screen-config.schema.json': { title: 'ScreenConfig', desc: 'Configuration d\\'un écran BDUI — layout, zones, composants' },
  'module-config.schema.json': { title: 'ModuleConfig', desc: 'Configuration complète d\\'un module — entités, actions, workflows, RBAC, ABAC' },
  'workflow.schema.json': { title: 'WorkflowDefinition', desc: 'Machine à états finis pour les processus métier' }
};

function generatePropertyRows(props, required, defs, depth) {
  if (!props) return '';
  const reqSet = new Set(required || []);
  let html = '';
  for (const [name, schema] of Object.entries(props)) {
    const isReq = reqSet.has(name);
    const type = schema.type || (schema.enum ? 'enum' : schema.const ? 'const' : schema.oneOf ? 'oneOf' : schema.anyOf ? 'anyOf' : schema.\$ref ? 'ref' : 'object');
    let typeStr = '<code>' + type + '</code>';
    if (schema.const !== undefined) typeStr = '<code>const: ' + JSON.stringify(schema.const) + '</code>';
    if (schema.enum) typeStr = '<code>enum: ' + schema.enum.join(', ') + '</code>';
    if (schema.\$ref) typeStr = '<code>' + schema.\$ref.split('/').pop() + '</code>';
    if (schema.oneOf) typeStr = '<code>oneOf</code>';
    if (schema.anyOf) typeStr = '<code>anyOf</code>';
    const desc = schema.description || '';
    const indent = 'padding-left:' + (depth * 20 + 8) + 'px';
    html += '<tr style=\"' + indent + '\"><td><code>' + name + '</code></td><td>' + typeStr + '</td><td>' + (isReq ? 'Yes' : 'No') + '</td><td>' + desc + '</td></tr>';
    if (schema.properties && depth < 3) {
      html += generatePropertyRows(schema.properties, schema.required, defs, depth + 1);
    }
  }
  return html;
}

function schemaToHtml(schemaFile) {
  const content = fs.readFileSync(path.join(schemasDir, schemaFile), 'utf-8');
  const schema = JSON.parse(content);
  const meta = schemaMeta[schemaFile] || { title: schema.title, desc: schema.description };

  let html = '<div class=\"schema-section\" id=\"' + schemaFile.replace('.schema.json', '') + '\">';
  html += '<h2>' + meta.title + '</h2>';
  html += '<p class=\"description\">' + meta.description + '</p>';
  html += '<p><strong>\$id:</strong> <code>' + schema.\$id + '</code></p>';
  html += '<p><strong>Version:</strong> <code>' + (schema.properties?.schema_version?.const || 'N/A') + '</code></p>';

  if (schema.required) {
    html += '<p><strong>Required fields:</strong> ' + schema.required.map(r => '<code>' + r + '</code>').join(', ') + '</p>';
  }

  if (schema.properties) {
    html += '<table><tr><th>Field</th><th>Type</th><th>Required</th><th>Description</th></tr>';
    html += generatePropertyRows(schema.properties, schema.required, schema.\$defs, 0);
    html += '</table>';
  }

  if (schema.\$defs) {
    html += '<h3>Definitions</h3>';
    for (const [defName, defSchema] of Object.entries(schema.\$defs)) {
      html += '<h4 id=\"def-' + defName + '\">' + defName + '</h4>';
      html += '<p>' + (defSchema.description || '') + '</p>';
      if (defSchema.properties) {
        html += '<table><tr><th>Field</th><th>Type</th><th>Required</th><th>Description</th></tr>';
        html += generatePropertyRows(defSchema.properties, defSchema.required, null, 0);
        html += '</table>';
      }
    }
  }

  html += '</div>';
  return html;
}

let indexHtml = '<!DOCTYPE html><html lang=\"fr\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">';
indexHtml += '<title>BDUI JSON Schema v1.0.0 — Documentation</title>';
indexHtml += '<style>body{font-family:system-ui,-apple-system,sans-serif;max-width:960px;margin:0 auto;padding:2rem;color:#1a1a1a}';
indexHtml += 'code{background:#f4f4f8;padding:2px 6px;border-radius:3px;font-size:0.9em}';
indexHtml += 'table{border-collapse:collapse;width:100%;margin:1rem 0}';
indexHtml += 'th,td{border:1px solid #ddd;padding:8px 12px;text-align:left}';
indexHtml += 'th{background:#f8f8fa}';
indexHtml += '.schema-section{margin:2rem 0;padding:1.5rem;border:1px solid #eee;border-radius:8px}';
indexHtml += 'h1{color:#2980b9}h2{color:#2c3e50}h3{color:#34495e}';
indexHtml += '.nav a{display:block;padding:4px 0;color:#2980b9;text-decoration:none}';
indexHtml += '.nav a:hover{text-decoration:underline}';
indexHtml += '</style></head><body>';
indexHtml += '<h1>BDUI JSON Schema v1.0.0 — Documentation</h1>';
indexHtml += '<p>Cette documentation est générée automatiquement à partir des schémas JSON Schema du catalogue BDUI Scalario.</p>';

indexHtml += '<div class=\"nav\"><h3>Schémas</h3>';
schemas.forEach(s => {
  const m = schemaMeta[s];
  indexHtml += '<a href=\"#' + s.replace('.schema.json', '') + '\">' + m.title + '</a>';
});
indexHtml += '</div>';

schemas.forEach(s => {
  indexHtml += schemaToHtml(s);
});

indexHtml += '<hr><p><em>Généré le ' + new Date().toISOString().split('T')[0] + ' —详见 <code>catalog/schemas/README.md</code> pour le guide intégrateur.</em></p>';
indexHtml += '</body></html>';

fs.writeFileSync(path.join(outputDir, 'index.html'), indexHtml, 'utf-8');
console.log('Generated: ' + path.join(outputDir, 'index.html'));
"

echo ""
echo "✅ Schema documentation built successfully in $OUTPUT_DIR"