// Pure logic utilities for data migration — testable without DB connection.

export interface TableCount {
  table: string;
  sourceCount: number;
  destCount: number;
}

export type RowStatus = 'OK' | 'MISMATCH' | 'DEST_EMPTY';

export interface TableReport extends TableCount {
  status: RowStatus;
}

export interface FkError {
  table: string;
  field: string;
  orphanCount: number;
}

export interface MigrationReport {
  tables: TableReport[];
  fkErrors: FkError[];
  warnings: string[];
  overallStatus: 'OK' | 'ERRORS';
  estimatedProdMs?: number;
}

/** Compare source vs destination row counts for each table. */
export function compareRowCounts(tables: TableCount[]): TableReport[] {
  return tables.map((t) => {
    let status: RowStatus;
    if (t.sourceCount === t.destCount) {
      status = 'OK';
    } else if (t.destCount === 0) {
      status = 'DEST_EMPTY';
    } else {
      status = 'MISMATCH';
    }
    return { ...t, status };
  });
}

/** Build the full migration report from table comparisons + FK errors. */
export function buildMigrationReport(
  tables: TableCount[],
  fkErrors: FkError[],
  warnings: string[] = [],
  durationMs?: number,
): MigrationReport {
  const tableReports = compareRowCounts(tables);
  const hasErrors =
    tableReports.some((r) => r.status !== 'OK') || fkErrors.length > 0;

  return {
    tables: tableReports,
    fkErrors,
    warnings,
    overallStatus: hasErrors ? 'ERRORS' : 'OK',
    estimatedProdMs: durationMs,
  };
}

/** Check FK integrity — returns list of errors for any orphan counts > 0. */
export function validateFkIntegrity(checks: FkError[]): {
  valid: boolean;
  errors: FkError[];
} {
  const errors = checks.filter((c) => c.orphanCount > 0);
  return { valid: errors.length === 0, errors };
}

/** Format a human-readable migration report. */
export function formatReport(report: MigrationReport): string {
  const lines: string[] = [];
  lines.push('=== Migration Report ===');
  lines.push(`Overall Status: ${report.overallStatus}`);
  lines.push('');
  lines.push('Table Row Counts:');
  for (const t of report.tables) {
    lines.push(
      `  ${t.table}: ${t.sourceCount} → ${t.destCount} [${t.status}]`,
    );
  }
  if (report.fkErrors.length > 0) {
    lines.push('');
    lines.push('FK Integrity Errors:');
    for (const e of report.fkErrors) {
      lines.push(`  ${e.table}.${e.field}: ${e.orphanCount} orphan(s)`);
    }
  }
  if (report.warnings.length > 0) {
    lines.push('');
    lines.push('Warnings:');
    for (const w of report.warnings) {
      lines.push(`  ⚠  ${w}`);
    }
  }
  if (report.estimatedProdMs !== undefined) {
    lines.push('');
    lines.push(
      `Estimated production migration time: ${(report.estimatedProdMs / 1000).toFixed(1)}s`,
    );
  }
  return lines.join('\n');
}
