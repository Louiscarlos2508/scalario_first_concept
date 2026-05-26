import { ScalarioTypeChecker } from '../scalario-type-checker';

describe('ScalarioTypeChecker', () => {
  const checker = new ScalarioTypeChecker();

  it('validates a simple pipeline with variable passing', () => {
    const result = checker.validate([
      { id: 's1', registry: 'calc', fn: 'mul', inputs: { a: { from: '$quantity' }, b: { literal: 100 } }, output: { name: 'total', type: 'number' } },
      { id: 's2', registry: 'calc', fn: 'div', inputs: { a: { from: '$total' }, b: { literal: 2 } }, output: { name: 'half', type: 'number' } },
    ]);
    expect(result.valid).toBe(true);
  });

  it('allows external variables from calling context', () => {
    const result = checker.validate([
      { id: 's1', registry: 'calc', fn: 'mul', inputs: { a: { from: '$external_var' }, b: { literal: 100 } } },
    ]);
    expect(result.valid).toBe(true);
  });

  it('validates empty pipeline', () => {
    expect(checker.validate([]).valid).toBe(true);
  });
});
