import { RetailModule } from './retail.module';
import { RetailController } from './retail.controller';
import { RetailSessionController } from './retail-session.controller';
import { RetailOrchestrationService } from './retail-orchestration.service';
import { RetailSaleService } from './retail-sale.service';
import { PosSessionService } from '../pos/pos-session.service';

describe('RetailModule', () => {
  it('register() returns a valid DynamicModule with correct shape (AC1)', () => {
    const dynamicModule = RetailModule.register();

    expect(dynamicModule.module).toBe(RetailModule);
    expect(dynamicModule.controllers).toContain(RetailController);
    expect(dynamicModule.controllers).toContain(RetailSessionController);
    expect(dynamicModule.providers).toContain(RetailOrchestrationService);
    expect(dynamicModule.providers).toContain(RetailSaleService);
    expect(dynamicModule.providers).toContain(PosSessionService);
    expect(dynamicModule.exports).toContain(RetailOrchestrationService);
  });

  it('register() imports required shared modules (AC1)', () => {
    const dynamicModule = RetailModule.register();

    expect(dynamicModule.imports).toBeDefined();
    expect(dynamicModule.imports!.length).toBeGreaterThanOrEqual(5);
  });
});
