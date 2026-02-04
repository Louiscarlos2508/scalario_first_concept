import { Controller, Post, Body, UseGuards, Request } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { AuthGuard } from '../core/guards/auth/auth.guard';

@Controller('organizations')
export class OrganizationController {
    constructor(private readonly organizationService: OrganizationService) { }

    @Post()
    @UseGuards(AuthGuard)
    async create(@Body('name') name: string, @Request() req) {
        const userId = req.user.id;
        return this.organizationService.createOrganization(name, userId);
    }
}
