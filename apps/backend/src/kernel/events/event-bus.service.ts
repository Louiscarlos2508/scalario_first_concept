import { Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';

@Injectable()
export class EventBusService {
  constructor(private readonly eventEmitter: EventEmitter2) {}

  publish(eventName: string, event: unknown): boolean {
    return this.eventEmitter.emit(eventName, event);
  }
}
