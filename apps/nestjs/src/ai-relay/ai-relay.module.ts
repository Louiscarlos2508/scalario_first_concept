import { Module } from '@nestjs/common';
import { ScalarioLiveModule } from '../engines/live/scalario-live.module';
import { MindModule } from '../engines/mind/mind.module';
import { AiRelayController } from './ai-relay.controller';
import { AiRelayService } from './services/ai-relay.service';

@Module({
  imports: [ScalarioLiveModule, MindModule],
  controllers: [AiRelayController],
  providers: [AiRelayService],
  exports: [AiRelayService],
})
export class AiRelayModule {}
