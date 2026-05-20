import { Injectable } from '@nestjs/common';
import type { Handler } from '../interfaces/handler.interface';

@Injectable()
export class HandlerRegistry {
  private readonly handlers = new Map<string, Handler>();

  register(handler: Handler): void {
    this.handlers.set(handler.type, handler);
  }

  get(type: string): Handler | undefined {
    return this.handlers.get(type);
  }

  getAll(): Handler[] {
    return Array.from(this.handlers.values());
  }
}
