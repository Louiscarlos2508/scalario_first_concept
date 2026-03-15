export class TransactionCreatedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly transactionId: string,
    public readonly amount: number,
    public readonly userId: string,
  ) {}
}

export class StockAdjustedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly productId: string,
    public readonly delta: number,
    public readonly reason: string,
  ) {}
}

export class SessionClosedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly sessionId: string,
    public readonly variance: number,
    public readonly userId: string,
  ) {}
}

export class BalanceUpdatedEvent {
  constructor(
    public readonly tenantId: string,
    public readonly contactId: string,
    public readonly previousBalance: number,
    public readonly newBalance: number,
  ) {}
}
