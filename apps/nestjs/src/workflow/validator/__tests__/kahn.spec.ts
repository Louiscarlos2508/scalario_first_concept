import { kahnTopologicalSort } from '../kahn';

describe('kahnTopologicalSort', () => {
  it('sorts a linear DAG: A -> B -> C', () => {
    const nodes = ['A', 'B', 'C'];
    const edges: ReadonlyArray<readonly [string, string]> = [
      ['A', 'B'],
      ['B', 'C'],
    ];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(true);
    expect(result.sorted).toEqual(['A', 'B', 'C']);
    expect(result.remaining).toEqual([]);
  });

  it('sorts a branching DAG: A -> B, A -> C, B -> D, C -> D', () => {
    const nodes = ['A', 'B', 'C', 'D'];
    const edges: ReadonlyArray<readonly [string, string]> = [
      ['A', 'B'],
      ['A', 'C'],
      ['B', 'D'],
      ['C', 'D'],
    ];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(true);
    expect(result.sorted).toContain('A');
    expect(result.sorted).toContain('B');
    expect(result.sorted).toContain('C');
    expect(result.sorted[result.sorted.length - 1]).toBe('D');
    expect(result.remaining).toEqual([]);
  });

  it('detects a simple cycle: A -> B -> A', () => {
    const nodes = ['A', 'B'];
    const edges: ReadonlyArray<readonly [string, string]> = [
      ['A', 'B'],
      ['B', 'A'],
    ];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(false);
    expect(result.remaining).toEqual(expect.arrayContaining(['A', 'B']));
  });

  it('detects a complex 3-node cycle: A -> B -> C -> A', () => {
    const nodes = ['A', 'B', 'C'];
    const edges: ReadonlyArray<readonly [string, string]> = [
      ['A', 'B'],
      ['B', 'C'],
      ['C', 'A'],
    ];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(false);
    expect(result.remaining).toEqual(expect.arrayContaining(['A', 'B', 'C']));
  });

  it('handles a single node with no edges', () => {
    const nodes = ['A'];
    const edges: ReadonlyArray<readonly [string, string]> = [];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(true);
    expect(result.sorted).toEqual(['A']);
    expect(result.remaining).toEqual([]);
  });

  it('handles multiple disconnected DAGs', () => {
    const nodes = ['A', 'B', 'C', 'D'];
    const edges: ReadonlyArray<readonly [string, string]> = [
      ['A', 'B'],
      ['C', 'D'],
    ];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(true);
    expect(result.sorted).toEqual(expect.arrayContaining(['A', 'B', 'C', 'D']));
    expect(result.remaining).toEqual([]);
  });

  it('detects cycle in partially cyclic graph', () => {
    const nodes = ['A', 'B', 'C', 'D'];
    const edges: ReadonlyArray<readonly [string, string]> = [
      ['A', 'B'],
      ['B', 'C'],
      ['C', 'A'],
    ];
    const result = kahnTopologicalSort(nodes, edges);
    expect(result.ok).toBe(false);
    expect(result.remaining).toEqual(expect.arrayContaining(['A', 'B', 'C']));
    expect(result.remaining).not.toContain('D');
  });

  it('returns empty remaining on empty nodes list', () => {
    const result = kahnTopologicalSort([], []);
    expect(result.ok).toBe(true);
    expect(result.sorted).toEqual([]);
    expect(result.remaining).toEqual([]);
  });

  it('handles DAG with 100 nodes in linear chain', () => {
    const nodes = Array.from({ length: 100 }, (_, i) => `N${i}`);
    const edges: ReadonlyArray<readonly [string, string]> = nodes
      .slice(0, -1)
      .map((n, i) => [n, nodes[i + 1]] as const);
    const start = performance.now();
    const result = kahnTopologicalSort(nodes, edges);
    const elapsed = performance.now() - start;
    expect(result.ok).toBe(true);
    expect(result.sorted.length).toBe(100);
    expect(elapsed).toBeLessThan(20);
  });
});
