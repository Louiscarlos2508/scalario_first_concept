import { Controller, Post, Body } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { CurrentUser } from '../kernel/auth/auth.decorator';

@Controller('organizations')
export class OrganizationController {
    constructor(private readonly organizationService: OrganizationService) { }

    @Post()
    async create(@Body('name') name: string, @CurrentUser() user: any) {
        return this.organizationService.createOrganization(name, user.id);
    }
}
