export interface KahnResult {
  ok: boolean;
  sorted: string[];
  remaining: string[];
}

export function kahnTopologicalSort(
  nodes: string[],
  edges: ReadonlyArray<readonly [string, string]>,
): KahnResult {
  const nodeSet = new Set(nodes);
  const uniqueNodes = [...nodeSet];
  const inDegree = new Map<string, number>(uniqueNodes.map((n) => [n, 0]));
  const adj = new Map<string, string[]>(uniqueNodes.map((n) => [n, []]));

  for (const [from, to] of edges) {
    if (!nodeSet.has(from) || !nodeSet.has(to)) continue;
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

  if (sorted.length === uniqueNodes.length) {
    return { ok: true, sorted, remaining: [] };
  }

  const remaining = [...inDegree.entries()].filter(([, d]) => d > 0).map(([n]) => n);
  return { ok: false, sorted: [], remaining };
}
