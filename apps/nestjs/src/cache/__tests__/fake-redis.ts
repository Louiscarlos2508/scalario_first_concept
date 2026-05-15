/**
 * Minimal in-memory Redis double for unit tests. Implements only the
 * subset of ioredis surface that STORY-018 services touch. Behaves like
 * `RedisService` (`isAvailable`, `getClient`, `getSubscriber`) so it can
 * be dropped in as a provider replacement.
 *
 * Pub/sub is wired so a single FakeRedis instance can simulate two
 * processes by exposing distinct subscriber objects that share state.
 */
type EventCallback = (channel: string, message: string) => void;

class Store {
  private values = new Map<string, { buf: Buffer; expiresAt: number | null }>();
  private listeners = new Map<string, Set<EventCallback>>();
  private timers: NodeJS.Timeout[] = [];

  set(key: string, value: Buffer, ttlSeconds?: number): void {
    const expiresAt = ttlSeconds ? Date.now() + ttlSeconds * 1000 : null;
    this.values.set(key, { buf: value, expiresAt });
    if (expiresAt) {
      const t = setTimeout(() => {
        const cur = this.values.get(key);
        if (cur && cur.expiresAt === expiresAt) this.values.delete(key);
      }, ttlSeconds! * 1000);
      // unref so jest exits cleanly
      (t as unknown as { unref?: () => void }).unref?.();
      this.timers.push(t);
    }
  }

  get(key: string): Buffer | null {
    const v = this.values.get(key);
    if (!v) return null;
    if (v.expiresAt !== null && v.expiresAt <= Date.now()) {
      this.values.delete(key);
      return null;
    }
    return v.buf;
  }

  del(keys: string[]): number {
    let n = 0;
    for (const k of keys) if (this.values.delete(k)) n++;
    return n;
  }

  keys(): string[] {
    return [...this.values.keys()];
  }

  exists(key: string): number {
    return this.get(key) === null ? 0 : 1;
  }

  publish(channel: string, message: string): number {
    const subs = this.listeners.get(channel);
    if (!subs) return 0;
    for (const cb of subs) {
      // async-ish — match ioredis behaviour (message arrives next tick)
      setImmediate(() => cb(channel, message));
    }
    return subs.size;
  }

  subscribe(channel: string, cb: EventCallback): void {
    if (!this.listeners.has(channel)) this.listeners.set(channel, new Set());
    this.listeners.get(channel)!.add(cb);
  }

  unsubscribeAll(cb: EventCallback): void {
    for (const set of this.listeners.values()) set.delete(cb);
  }

  reset(): void {
    this.values.clear();
    this.listeners.clear();
    for (const t of this.timers) clearTimeout(t);
    this.timers = [];
  }
}

export interface FakeClient {
  set(key: string, value: string | Buffer, mode: 'EX', ttlSeconds: number): Promise<'OK'>;
  get(key: string): Promise<string | null>;
  getBuffer(key: string): Promise<Buffer | null>;
  exists(key: string): Promise<number>;
  del(...keys: string[]): Promise<number>;
  incr(key: string): Promise<number>;
  expire(key: string, ttlSeconds: number): Promise<number>;
  publish(channel: string, message: string): Promise<number>;
  scanStream(opts: { match: string; count?: number }): AsyncIterable<string[]>;
  ping(): Promise<'PONG'>;
}

export interface FakeSubscriber {
  subscribe(channel: string): Promise<void>;
  on(event: 'message', cb: EventCallback): void;
}

function patternToRegex(pattern: string): RegExp {
  // ioredis SCAN patterns use `*` glob style.
  const escaped = pattern.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*');
  return new RegExp(`^${escaped}$`);
}

export class FakeRedisService {
  private readonly store: Store;
  private readonly client: FakeClient;
  private readonly subscriberHandlers: EventCallback[] = [];
  private readonly subscriber: FakeSubscriber;
  private readonly counters = new Map<string, number>();

  constructor(store?: Store) {
    this.store = store ?? new Store();

    const incr = async (key: string): Promise<number> => {
      const cur = (this.counters.get(key) ?? 0) + 1;
      this.counters.set(key, cur);
      return cur;
    };

    this.client = {
      set: async (key, value, _mode, ttl) => {
        const buf = typeof value === 'string' ? Buffer.from(value, 'utf8') : value;
        this.store.set(key, buf, ttl);
        return 'OK';
      },
      get: async (key) => {
        const buf = this.store.get(key);
        return buf ? buf.toString('utf8') : null;
      },
      getBuffer: async (key) => this.store.get(key),
      exists: async (key) => this.store.exists(key),
      del: async (...keys: string[]) => this.store.del(keys),
      incr,
      expire: async () => 1,
      publish: async (channel, message) => this.store.publish(channel, message),
      scanStream: ({ match }) => {
        const re = patternToRegex(match);
        const keys = this.store.keys().filter((k) => re.test(k));
        return {
          [Symbol.asyncIterator]() {
            let yielded = false;
            return {
              async next() {
                if (yielded) return { value: undefined as unknown as string[], done: true };
                yielded = true;
                return { value: keys, done: false };
              },
            };
          },
        };
      },
      ping: async () => 'PONG' as const,
    };

    const dispatchAll = (channel: string, message: string) => {
      for (const cb of this.subscriberHandlers) cb(channel, message);
    };

    this.subscriber = {
      subscribe: async (channel) => {
        this.store.subscribe(channel, dispatchAll);
      },
      on: (event, cb) => {
        if (event === 'message') this.subscriberHandlers.push(cb);
      },
    };
  }

  isAvailable(): boolean {
    return true;
  }

  getClient(): FakeClient {
    return this.client;
  }

  getSubscriber(): FakeSubscriber {
    return this.subscriber;
  }

  /** Shared backing store — useful when simulating multiple "nodes". */
  getStore(): Store {
    return this.store;
  }

  reset(): void {
    this.store.reset();
    this.counters.clear();
    this.subscriberHandlers.length = 0;
  }
}

export function pair(): { a: FakeRedisService; b: FakeRedisService; store: Store } {
  const store = new Store();
  return {
    a: new FakeRedisService(store),
    b: new FakeRedisService(store),
    store,
  };
}
