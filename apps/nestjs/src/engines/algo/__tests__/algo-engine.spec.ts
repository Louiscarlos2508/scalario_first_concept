import { AlgoEngineService } from '../algo-engine.service';

describe('AlgoEngineService', () => {
  let engine: AlgoEngineService;

  beforeEach(() => {
    engine = new AlgoEngineService();
  });

  describe('Math primitives', () => {
    it('add', () => {
      expect(engine.eval({ fn: 'add', args: [2, 3] }, {}).value).toBe(5);
    });
    it('sub', () => {
      expect(engine.eval({ fn: 'sub', args: [10, 3] }, {}).value).toBe(7);
    });
    it('mul', () => {
      expect(engine.eval({ fn: 'mul', args: [4, 5] }, {}).value).toBe(20);
    });
    it('div', () => {
      expect(engine.eval({ fn: 'div', args: [10, 2] }, {}).value).toBe(5);
    });
    it('div/0 throws', () => {
      expect(() => engine.eval({ fn: 'div', args: [5, 0] }, {})).toThrow();
    });
    it('round', () => {
      expect(engine.eval({ fn: 'round', args: [3.14159, 2] }, {}).value).toBe(3.14);
    });
    it('floor', () => {
      expect(engine.eval({ fn: 'floor', args: [3.9] }, {}).value).toBe(3);
    });
    it('ceil', () => {
      expect(engine.eval({ fn: 'ceil', args: [3.1] }, {}).value).toBe(4);
    });
    it('abs', () => {
      expect(engine.eval({ fn: 'abs', args: [-5] }, {}).value).toBe(5);
    });
    it('min', () => {
      expect(engine.eval({ fn: 'min', args: [2, 5] }, {}).value).toBe(2);
    });
    it('max', () => {
      expect(engine.eval({ fn: 'max', args: [2, 5] }, {}).value).toBe(5);
    });
  });

  describe('Logic primitives', () => {
    it('if true', () => {
      expect(engine.eval({ fn: 'if', args: [true, 'yes', 'no'] }, {}).value).toBe('yes');
    });
    it('if false', () => {
      expect(engine.eval({ fn: 'if', args: [false, 'yes', 'no'] }, {}).value).toBe('no');
    });
    it('gt', () => {
      expect(engine.eval({ fn: 'gt', args: [5, 3] }, {}).value).toBe(true);
    });
    it('lt', () => {
      expect(engine.eval({ fn: 'lt', args: [3, 5] }, {}).value).toBe(true);
    });
    it('eq', () => {
      expect(engine.eval({ fn: 'eq', args: [42, 42] }, {}).value).toBe(true);
    });
    it('ne', () => {
      expect(engine.eval({ fn: 'ne', args: [1, 2] }, {}).value).toBe(true);
    });
    it('and', () => {
      expect(engine.eval({ fn: 'and', args: [true, true] }, {}).value).toBe(true);
      expect(engine.eval({ fn: 'and', args: [true, false] }, {}).value).toBe(false);
    });
    it('or', () => {
      expect(engine.eval({ fn: 'or', args: [false, true] }, {}).value).toBe(true);
    });
    it('not', () => {
      expect(engine.eval({ fn: 'not', args: [false] }, {}).value).toBe(true);
    });
  });

  describe('List primitives', () => {
    it('sum', () => {
      expect(engine.eval({ fn: 'sum', args: [[1, 2, 3, 4]] }, {}).value).toBe(10);
    });
    it('avg', () => {
      expect(engine.eval({ fn: 'avg', args: [[2, 4, 6]] }, {}).value).toBe(4);
    });
    it('avg empty returns null', () => {
      expect(engine.eval({ fn: 'avg', args: [[]] }, {}).value).toBeNull();
    });
    it('count', () => {
      expect(engine.eval({ fn: 'count', args: [['a', 'b', 'c']] }, {}).value).toBe(3);
    });
    it('filter', () => {
      const data = [{ name: 'a', cat: 'x' }, { name: 'b', cat: 'y' }, { name: 'c', cat: 'x' }];
      const r = engine.eval({ fn: 'filter', args: [data, 'cat', 'x'] }, {});
      expect((r.value as any[]).length).toBe(2);
    });
    it('map_field', () => {
      const data = [{ name: 'a', val: 1 }, { name: 'b', val: 2 }];
      const r = engine.eval({ fn: 'map_field', args: [data, 'val'] }, {});
      expect(r.value).toEqual([1, 2]);
    });
    it('unique', () => {
      expect(engine.eval({ fn: 'unique', args: [[1, 2, 2, 3, 3, 3]] }, {}).value).toEqual([1, 2, 3]);
    });
  });

  describe('Date primitives', () => {
    it('today returns string', () => {
      const r = engine.eval({ fn: 'today', args: [] }, {});
      expect(typeof r.value).toBe('string');
    });
    it('diff_jours', () => {
      const r = engine.eval({ fn: 'diff_jours', args: ['2026-05-30', '2026-05-20'] }, {});
      expect(r.value).toBe(10);
    });
    it('add_days', () => {
      const r = engine.eval({ fn: 'add_days', args: ['2026-05-01', 5] }, {});
      expect(r.value).toBe('2026-05-06');
    });
    it('format_date DD/MM/YYYY', () => {
      const r = engine.eval({ fn: 'format_date', args: ['2026-05-25', 'DD/MM/YYYY'] }, {});
      expect(r.value).toBe('25/05/2026');
    });
  });

  describe('Text primitives', () => {
    it('concat', () => {
      expect(engine.eval({ fn: 'concat', args: ['Hello ', 'World'] }, {}).value).toBe('Hello World');
    });
    it('upper', () => {
      expect(engine.eval({ fn: 'upper', args: ['hello'] }, {}).value).toBe('HELLO');
    });
    it('lower', () => {
      expect(engine.eval({ fn: 'lower', args: ['HELLO'] }, {}).value).toBe('hello');
    });
    it('format_currency XOF', () => {
      const r = engine.eval({ fn: 'format_currency', args: [125000, 'XOF'] }, {});
      expect(r.value).toContain('FCFA');
    });
    it('slugify', () => {
      expect(engine.eval({ fn: 'slugify', args: ['Pharmacie Kossyam'] }, {}).value).toBe('pharmacie-kossyam');
    });
  });

  describe('Variable resolution', () => {
    it('resolves $variable from inputs', () => {
      const r = engine.eval('$quantite', { quantite: 10 });
      expect(r.value).toBe(10);
    });
    it('throws on missing variable', () => {
      expect(() => engine.eval('$missing', {})).toThrow();
    });
  });

  describe('Nested formulas', () => {
    it('(10 * 1000 - (10 * 1000 * 5/100)) * 1.18 = 11210', () => {
      const formula = {
        fn: 'mul',
        args: [
          {
            fn: 'sub',
            args: [
              { fn: 'mul', args: ['$quantite', '$prix_unitaire'] },
              {
                fn: 'mul',
                args: [
                  { fn: 'mul', args: ['$quantite', '$prix_unitaire'] },
                  { fn: 'div', args: ['$remise', 100] },
                ],
              },
            ],
          },
          1.18,
        ],
      };
      const r = engine.eval(formula, { quantite: 10, prix_unitaire: 1000, remise: 5 });
      expect(r.value).toBe(11210);
    });
  });

  describe('Debug mode', () => {
    it('returns steps when debug: true', () => {
      const r = engine.eval({ fn: 'add', args: [2, 3] }, {}, { debug: true });
      expect(r.steps).toBeDefined();
      expect(r.steps!.length).toBeGreaterThan(0);
      expect(r.steps![0].fn).toBe('add');
      expect(r.steps![0].result).toBe(5);
    });
  });

  describe('Edge cases', () => {
    it('handles NaN in add', () => {
      expect(() => engine.eval({ fn: 'add', args: [NaN, 3] }, {})).toThrow();
    });
    it('throws on unknown function', () => {
      expect(() => engine.eval({ fn: 'unknown_fn', args: [] }, {})).toThrow();
    });
    it('throws on max depth', () => {
      let deep: any = { fn: 'add', args: [1, 1] };
      for (let i = 0; i < 110; i++) {
        deep = { fn: 'add', args: [deep, 1] };
      }
      expect(() => engine.eval(deep, {})).toThrow(/depth/);
    });
  });
});
