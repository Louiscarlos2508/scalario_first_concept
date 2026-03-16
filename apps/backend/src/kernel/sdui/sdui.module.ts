import { Module } from '@nestjs/common';
import { SduiController } from './sdui.controller';
import { SduiService } from './sdui.service';

@Module({
  controllers: [SduiController],
  providers: [SduiService],
  exports: [SduiService],
})
export class SduiModule {}
