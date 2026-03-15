import {
  buildMigrationReport,
  compareRowCounts,
  validateFkIntegrity,
  formatReport,
  TableCount,
  FkError,
} from './migration-utils';

describe('migration-utils', () => {
  // ── compareRowCounts ────────────────────────────────────────────────────────

  describe('compareRowCounts', () => {
    it('marks tables OK when source === dest', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 10, destCount: 10 },
        { table: 'retail_products', sourceCount: 10, destCount: 10 },
      ];
      const result = compareRowCounts(tables);
      expect(result[0].status).toBe('OK');
      expect(result[1].status).toBe('OK');
    });

    it('marks MISMATCH when counts differ but dest > 0', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 10, destCount: 8 },
      ];
      const result = compareRowCounts(tables);
      expect(result[0].status).toBe('MISMATCH');
    });

    it('marks DEST_EMPTY when dest count is 0 and source > 0', () => {
      const tables: TableCount[] = [
        { table: 'retail_products', sourceCount: 5, destCount: 0 },
      ];
      const result = compareRowCounts(tables);
      expect(result[0].status).toBe('DEST_EMPTY');
    });

    it('marks OK when both source and dest are 0 (empty table)', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 0, destCount: 0 },
      ];
      const result = compareRowCounts(tables);
      expect(result[0].status).toBe('OK');
    });
  });

  // ── buildMigrationReport ────────────────────────────────────────────────────

  describe('buildMigrationReport (AC4)', () => {
    it('returns overallStatus OK when all tables match and no FK errors', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 5, destCount: 5 },
        { table: 'retail_products', sourceCount: 5, destCount: 5 },
      ];
      const report = buildMigrationReport(tables, []);
      expect(report.overallStatus).toBe('OK');
      expect(report.fkErrors).toHaveLength(0);
      expect(report.tables).toHaveLength(2);
      expect(report.tables[0].status).toBe('OK');
    });

    it('returns overallStatus ERRORS when a table has MISMATCH', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 10, destCount: 7 },
      ];
      const report = buildMigrationReport(tables, []);
      expect(report.overallStatus).toBe('ERRORS');
    });

    it('returns overallStatus ERRORS when FK errors are present', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 5, destCount: 5 },
      ];
      const fkErrors: FkError[] = [
        { table: 'retail_products', field: 'catalog_item_id', orphanCount: 2 },
      ];
      const report = buildMigrationReport(tables, fkErrors);
      expect(report.overallStatus).toBe('ERRORS');
      expect(report.fkErrors).toHaveLength(1);
    });

    it('includes estimatedProdMs when duration provided', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 3, destCount: 3 },
      ];
      const report = buildMigrationReport(tables, [], [], 4200);
      expect(report.estimatedProdMs).toBe(4200);
    });

    it('includes warnings in report', () => {
      const tables: TableCount[] = [
        { table: 'catalog_items', sourceCount: 3, destCount: 3 },
      ];
      const report = buildMigrationReport(tables, [], ['Some item has null barcode'], 1000);
      expect(report.warnings).toHaveLength(1);
      expect(report.warnings[0]).toContain('null barcode');
    });
  });

  // ── validateFkIntegrity ────────────────────────────────────────────────────

  describe('validateFkIntegrity (AC2)', () => {
    it('returns valid=true when no orphans', () => {
      const checks: FkError[] = [
        { table: 'retail_products', field: 'catalog_item_id', orphanCount: 0 },
        { table: 'retail_sales', field: 'transaction_id', orphanCount: 0 },
      ];
      const result = validateFkIntegrity(checks);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('returns valid=false with errors when orphans detected (AC2)', () => {
      const checks: FkError[] = [
        { table: 'retail_products', field: 'catalog_item_id', orphanCount: 3 },
        { table: 'retail_sales', field: 'transaction_id', orphanCount: 0 },
      ];
      const result = validateFkIntegrity(checks);
      expect(result.valid).toBe(false);
      expect(result.errors).toHaveLength(1);
      expect(result.errors[0].table).toBe('retail_products');
      expect(result.errors[0].orphanCount).toBe(3);
    });

    it('returns valid=false when all checks have orphans', () => {
      const checks: FkError[] = [
        { table: 'retail_products', field: 'catalog_item_id', orphanCount: 2 },
        { table: 'retail_sales', field: 'session_id', orphanCount: 1 },
      ];
      const result = validateFkIntegrity(checks);
      expect(result.valid).toBe(false);
      expect(result.errors).toHaveLength(2);
    });
  });

  // ── formatReport ───────────────────────────────────────────────────────────

  describe('formatReport', () => {
    it('formats a clean report with OK status', () => {
      const report = buildMigrationReport(
        [{ table: 'catalog_items', sourceCount: 5, destCount: 5 }],
        [],
        [],
        2000,
      );
      const output = formatReport(report);
      expect(output).toContain('Overall Status: OK');
      expect(output).toContain('catalog_items: 5 → 5 [OK]');
      expect(output).toContain('Estimated production migration time: 2.0s');
    });

    it('includes FK errors section when errors present', () => {
      const report = buildMigrationReport(
        [{ table: 'catalog_items', sourceCount: 5, destCount: 5 }],
        [{ table: 'retail_products', field: 'catalog_item_id', orphanCount: 3 }],
      );
      const output = formatReport(report);
      expect(output).toContain('FK Integrity Errors');
      expect(output).toContain('retail_products.catalog_item_id: 3 orphan(s)');
    });
  });
});
