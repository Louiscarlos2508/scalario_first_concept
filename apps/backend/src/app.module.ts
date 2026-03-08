import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { KernelModule } from './kernel/kernel.module';
import { OrganizationModule } from './organization/organization.module';
import { PosModule } from './pos/pos.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [KernelModule, OrganizationModule, PosModule, PrismaModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
