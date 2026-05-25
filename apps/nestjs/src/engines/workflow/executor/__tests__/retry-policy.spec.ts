import { RetryPolicy } from '../retry-policy';

describe('RetryPolicy', () => {
  let policy: RetryPolicy;

  beforeEach(() => {
    policy = new RetryPolicy([50, 100, 200]);
  });

  describe('execute', () => {
    it('returns result on first attempt when no error', async () => {
      const result = await policy.execute(() => Promise.resolve('ok'), {
        stepId: 'step-1',
      });
      expect(result.result).toBe('ok');
      expect(result.attempts).toBe(1);
    });

    it('retries on transient error and succeeds', async () => {
      let callCount = 0;
      const fn = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount < 3) {
          const err = new Error('timeout');
          (err as any).code = 'ETIMEDOUT';
          throw err;
        }
        return Promise.resolve('ok');
      });

      const result = await policy.execute(fn, { stepId: 'step-1' });
      expect(result.result).toBe('ok');
      expect(result.attempts).toBe(3);
      expect(fn).toHaveBeenCalledTimes(3);
    });

    it('retries on 5xx status errors', async () => {
      let callCount = 0;
      const fn = jest.fn().mockImplementation(() => {
        callCount++;
        if (callCount < 2) {
          const err = new Error('bad gateway');
          (err as any).status = 502;
          throw err;
        }
        return Promise.resolve('ok');
      });

      const result = await policy.execute(fn, { stepId: 'step-1' });
      expect(result.result).toBe('ok');
      expect(result.attempts).toBe(2);
    });

    it('does not retry on 4xx business errors', async () => {
      const fn = jest.fn().mockImplementation(() => {
        const err = new Error('unprocessable');
        (err as any).status = 422;
        throw err;
      });

      await expect(policy.execute(fn, { stepId: 'step-1' })).rejects.toThrow('unprocessable');
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('does not retry on WorkflowExecutionError', async () => {
      const fn = jest.fn().mockImplementation(() => {
        const err: any = new Error('UNSUPPORTED_STEP_TYPE');
        err.name = 'WorkflowExecutionError';
        throw err;
      });

      await expect(policy.execute(fn, { stepId: 'step-1' })).rejects.toThrow();
      expect(fn).toHaveBeenCalledTimes(1);
    });

    it('exhausts retries and throws the last error', async () => {
      const fn = jest.fn().mockImplementation(() => {
        const err = new Error('timeout');
        (err as any).code = 'ETIMEDOUT';
        throw err;
      });

      await expect(policy.execute(fn, { stepId: 'step-1' })).rejects.toThrow('timeout');
      expect(fn).toHaveBeenCalledTimes(4);
    });
  });

  describe('isTransient', () => {
    it('identifies ECONNRESET as transient', () => {
      const err: any = { code: 'ECONNRESET' };
      expect(policy.isTransient(err)).toBe(true);
    });

    it('identifies ETIMEDOUT as transient', () => {
      const err: any = { code: 'ETIMEDOUT' };
      expect(policy.isTransient(err)).toBe(true);
    });

    it('identifies ECONNREFUSED as transient', () => {
      const err: any = { code: 'ECONNREFUSED' };
      expect(policy.isTransient(err)).toBe(true);
    });

    it('identifies 5xx as transient', () => {
      expect(policy.isTransient({ status: 502 } as any)).toBe(true);
      expect(policy.isTransient({ status: 503 } as any)).toBe(true);
      expect(policy.isTransient({ status: 504 } as any)).toBe(true);
    });

    it('does not identify 4xx as transient', () => {
      expect(policy.isTransient({ status: 400 } as any)).toBe(false);
      expect(policy.isTransient({ status: 422 } as any)).toBe(false);
    });

    it('does not identify null as transient', () => {
      expect(policy.isTransient(null)).toBe(false);
    });
  });
});
