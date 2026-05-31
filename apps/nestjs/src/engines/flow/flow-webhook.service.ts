import { Injectable, Logger } from '@nestjs/common';
import { createHmac } from 'crypto';

@Injectable()
export class FlowWebhookService {
  private readonly logger = new Logger(FlowWebhookService.name);
  private readonly MAX_RETRIES = 3;

  async call(config: Record<string, unknown>): Promise<{
    success: boolean;
    status?: number;
    body?: string;
    duration?: number;
  }> {
    const url = config.url as string;
    const method = (config.method as string) ?? 'POST';
    const timeout = (config.timeout as number) ?? 10000;
    const hmacSecret = config.hmac_secret as string | undefined;

    for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
      const start = Date.now();
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);

      try {
        const headers: Record<string, string> = {
          'Content-Type': 'application/json',
          ...((config.headers as Record<string, string>) ?? {}),
        };

        const body = config.body !== undefined ? JSON.stringify(config.body) : undefined;

        if (hmacSecret && body) {
          const signature = createHmac('sha256', hmacSecret).update(body).digest('hex');
          headers['X-Signature-256'] = signature;
        }

        const response = await fetch(url, {
          method,
          headers,
          body,
          signal: controller.signal,
        });
        const duration = Date.now() - start;
        const responseBody = await response.text().catch(() => '');

        this.logger.log(
          `Webhook ${method} ${url} → ${response.status} (${duration}ms, attempt #${attempt})`,
        );

        if (response.ok) {
          return { success: true, status: response.status, body: responseBody, duration };
        }

        if (response.status === 429 || response.status >= 500) {
          if (attempt < this.MAX_RETRIES) {
            const backoff = Math.pow(4, attempt - 1) * 1000;
            clearTimeout(timeoutId);
            await new Promise((r) => setTimeout(r, backoff));
            continue;
          }
          return { success: false, status: response.status, duration };
        }

        return { success: false, status: response.status, duration };
      } catch (error) {
        const duration = Date.now() - start;
        clearTimeout(timeoutId);
        if (attempt < this.MAX_RETRIES) {
          const backoff = Math.pow(4, attempt - 1) * 1000;
          this.logger.warn(
            `Webhook ${method} ${url} failed (attempt #${attempt}): ${error}, retry in ${backoff}ms`,
          );
          await new Promise((r) => setTimeout(r, backoff));
          continue;
        }
        this.logger.error(
          `Webhook ${method} ${url} failed after ${this.MAX_RETRIES} attempts: ${error}`,
        );
        return { success: false, duration };
      }
    }

    return { success: false };
  }
}
