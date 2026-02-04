import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CoreModule } from './core/core.module';
import { OrganizationModule } from './organization/organization.module';
import { TenantsModule } from './tenants/tenants.module';

@Module({
  imports: [CoreModule, OrganizationModule, TenantsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
