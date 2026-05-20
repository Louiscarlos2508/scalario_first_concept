export interface KahnResult {
  ok: boolean;
  sorted: string[];
  remaining: string[];
}

export function kahnTopologicalSort(
  nodes: string[],
  edges: ReadonlyArray<readonly [string, string]>,
): KahnResult {
  const inDegree = new Map<string, number>(nodes.map((n) => [n, 0]));
  const adj = new Map<string, string[]>(nodes.map((n) => [n, []]));

  for (const [from, to] of edges) {
    adj.get(from)!.push(to);
    inDegree.set(to, (inDegree.get(to) ?? 0) + 1);
  }

  const queue: string[] = [];
  for (const [n, deg] of inDegree) {
    if (deg === 0) queue.push(n);
  }

  const sorted: string[] = [];
  while (queue.length > 0) {
    const n = queue.shift()!;
    sorted.push(n);
    for (const next of adj.get(n) ?? []) {
      const d = (inDegree.get(next) ?? 0) - 1;
      inDegree.set(next, d);
      if (d === 0) queue.push(next);
    }
  }

  if (sorted.length === nodes.length) {
    return { ok: true, sorted, remaining: [] };
  }

  const remaining = [...inDegree.entries()].filter(([, d]) => d > 0).map(([n]) => n);
  return { ok: false, sorted: [], remaining };
}
