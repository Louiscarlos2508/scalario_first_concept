import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CoreModule } from './core/core.module';
import { OrganizationModule } from './organization/organization.module';
import { TenantsModule } from './tenants/tenants.module';
import { PosModule } from './pos/pos.module';
import { PrismaModule } from './prisma/prisma.module';

@Module({
  imports: [CoreModule, OrganizationModule, TenantsModule, PosModule, PrismaModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
