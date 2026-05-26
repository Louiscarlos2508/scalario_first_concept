import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ScalarioLiveGateway } from './scalario-live.gateway';
import { ScalarioLiveService } from './scalario-live.service';
import { PushService } from './push.service';

@Module({
  imports: [JwtModule.register({})],
  providers: [ScalarioLiveGateway, ScalarioLiveService, PushService],
  exports: [ScalarioLiveService, PushService],
})
export class ScalarioLiveModule {}
