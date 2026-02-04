import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { SupabaseService } from '../core/services/supabase/supabase.service';

@Injectable()
export class OrganizationService {
    constructor(private readonly supabaseService: SupabaseService) { }

    async createOrganization(name: string, userId: string) {
        const supabase = this.supabaseService.getClient();

        // 1. Create Tenant
        const { data: tenant, error: tenantError } = await supabase
            .from('tenants')
            .insert({ name })
            .select()
            .single();

        if (tenantError) {
            throw new InternalServerErrorException('Failed to create organization: ' + tenantError.message);
        }

        // 2. Link User as Owner
        const { error: memberError } = await supabase
            .from('organization_members')
            .insert({
                organization_id: tenant.id,
                user_id: userId,
                role: 'owner',
            });

        if (memberError) {
            // Rollback would be ideal here (delete tenant)
            throw new InternalServerErrorException('Failed to add member to organization: ' + memberError.message);
        }

        return tenant;
    }
}
