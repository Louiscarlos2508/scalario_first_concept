import { FlowWebhookService } from '../flow-webhook.service';

jest.setTimeout(15000);

describe('FlowWebhookService', () => {
  let service: FlowWebhookService;

  beforeEach(() => {
    service = new FlowWebhookService();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  function mockFetch(
    status: number,
    body = '',
    ok?: boolean,
  ): jest.SpyInstance {
    return jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: ok ?? (status >= 200 && status < 300),
      status,
      text: jest.fn().mockResolvedValue(body),
    } as unknown as Response);
  }

  describe('call', () => {
    it('performs a successful request and returns status/body', async () => {
      const fetchMock = mockFetch(200, '{"ok":true}');

      const result = await service.call({
        url: 'https://example.com/webhook',
        method: 'POST',
        body: { key: 'value' },
      });

      expect(result).toEqual({
        success: true,
        status: 200,
        body: '{"ok":true}',
        duration: expect.any(Number),
      });
      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(fetchMock).toHaveBeenCalledWith(
        'https://example.com/webhook',
        expect.objectContaining({
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: '{"key":"value"}',
        }),
      );
    });

    it('defaults method to POST', async () => {
      const fetchMock = mockFetch(200);

      await service.call({ url: 'https://example.com/hook' });

      expect(fetchMock).toHaveBeenCalledWith(
        'https://example.com/hook',
        expect.objectContaining({ method: 'POST' }),
      );
    });

    it('returns failure for 4xx status without retry', async () => {
      mockFetch(404);

      const result = await service.call({
        url: 'https://example.com/webhook',
        method: 'GET',
      });

      expect(result).toEqual({
        success: false,
        status: 404,
        duration: expect.any(Number),
      });
    });

    it('returns failure for 403 without retry', async () => {
      mockFetch(403);

      const result = await service.call({
        url: 'https://example.com/webhook',
        method: 'GET',
      });

      expect(result.success).toBe(false);
      expect(result.status).toBe(403);
    });

    it('retries 3 times on 500 and returns failure', async () => {
      jest.useFakeTimers({ advanceTimers: true });
      const fetchMock = mockFetch(500);

      const resultPromise = service.call({
        url: 'https://example.com/webhook',
        method: 'GET',
      });

      await jest.advanceTimersByTimeAsync(50000);
      const result = await resultPromise;

      expect(result.success).toBe(false);
      expect(result.status).toBe(500);
      expect(fetchMock).toHaveBeenCalledTimes(3);
      jest.useRealTimers();
    });

    it('retries 3 times on 429 and returns failure', async () => {
      jest.useFakeTimers({ advanceTimers: true });
      const fetchMock = mockFetch(429);

      const resultPromise = service.call({
        url: 'https://example.com/webhook',
        method: 'GET',
      });

      await jest.advanceTimersByTimeAsync(50000);
      const result = await resultPromise;

      expect(result.success).toBe(false);
      expect(result.status).toBe(429);
      expect(fetchMock).toHaveBeenCalledTimes(3);
      jest.useRealTimers();
    });

    it('succeeds on third retry after two 500 failures', async () => {
      jest.useFakeTimers({ advanceTimers: true });
      const fetchMock = jest
        .spyOn(global, 'fetch')
        .mockResolvedValueOnce({
          ok: false,
          status: 500,
          text: jest.fn().mockResolvedValue(''),
        } as unknown as Response)
        .mockResolvedValueOnce({
          ok: false,
          status: 500,
          text: jest.fn().mockResolvedValue(''),
        } as unknown as Response)
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          text: jest.fn().mockResolvedValue('{"success":true}'),
        } as unknown as Response);

      const resultPromise = service.call({
        url: 'https://example.com/webhook',
        method: 'GET',
      });

      await jest.advanceTimersByTimeAsync(50000);
      const result = await resultPromise;

      expect(result.success).toBe(true);
      expect(result.status).toBe(200);
      expect(fetchMock).toHaveBeenCalledTimes(3);
      jest.useRealTimers();
    });

    it('retries 3 times on network error', async () => {
      jest.useFakeTimers({ advanceTimers: true });
      const fetchMock = jest
        .spyOn(global, 'fetch')
        .mockRejectedValue(new Error('ECONNREFUSED'));

      const resultPromise = service.call({
        url: 'https://example.com/webhook',
        method: 'GET',
      });

      await jest.advanceTimersByTimeAsync(50000);
      const result = await resultPromise;

      expect(result.success).toBe(false);
      expect(fetchMock).toHaveBeenCalledTimes(3);
      jest.useRealTimers();
    });

    it('passes custom headers from config', async () => {
      const fetchMock = mockFetch(200);

      await service.call({
        url: 'https://example.com/hook',
        method: 'POST',
        headers: { Authorization: 'Bearer token123', 'X-Custom': 'val' },
      });

      expect(fetchMock).toHaveBeenCalledWith(
        'https://example.com/hook',
        expect.objectContaining({
          headers: {
            'Content-Type': 'application/json',
            Authorization: 'Bearer token123',
            'X-Custom': 'val',
          },
        }),
      );
    });

    it('adds X-Signature-256 header when hmac_secret provided with body', async () => {
      const fetchMock = mockFetch(200);

      await service.call({
        url: 'https://example.com/hook',
        method: 'POST',
        body: { message: 'hello' },
        hmac_secret: 'my-secret',
      });

      const callArgs = fetchMock.mock.calls[0][1] as RequestInit;
      const headers = callArgs.headers as Record<string, string>;
      expect(headers['X-Signature-256']).toBeDefined();
      expect(headers['X-Signature-256']).toMatch(/^[a-f0-9]{64}$/);
    });

    it('omits HMAC header when body is empty', async () => {
      const fetchMock = mockFetch(200);

      await service.call({
        url: 'https://example.com/hook',
        method: 'POST',
        hmac_secret: 'my-secret',
      });

      const callArgs = fetchMock.mock.calls[0][1] as RequestInit;
      const headers = callArgs.headers as Record<string, string>;
      expect(headers['X-Signature-256']).toBeUndefined();
    });

    it('omits HMAC header when there is no body', async () => {
      const fetchMock = mockFetch(200);

      await service.call({
        url: 'https://example.com/hook',
        method: 'GET',
        hmac_secret: 'my-secret',
      });

      const callArgs = fetchMock.mock.calls[0][1] as RequestInit;
      const headers = callArgs.headers as Record<string, string>;
      expect(headers['X-Signature-256']).toBeUndefined();
    });

    it('aborts on timeout and returns failure', async () => {
      jest
        .spyOn(global, 'fetch')
        .mockImplementation(async (_url, init) => {
          await new Promise((r) => setTimeout(r, 100));
          if ((init?.signal as AbortSignal)?.aborted) {
            throw new DOMException('Aborted', 'AbortError');
          }
          return {
            ok: true,
            status: 200,
            text: jest.fn().mockResolvedValue(''),
          } as unknown as Response;
        });

      const result = await service.call({
        url: 'https://example.com/hook',
        method: 'GET',
        timeout: 5,
      });

      expect(result.success).toBe(false);
    }, 10000);

    it('reports duration in milliseconds', async () => {
      mockFetch(200);

      const result = await service.call({
        url: 'https://example.com/hook',
        method: 'GET',
      });

      expect(result.duration).toBeGreaterThanOrEqual(0);
    });
  });
});
