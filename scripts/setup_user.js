const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'http://127.0.0.1:54321';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU'; // Default local service key

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setup() {
    const email = 'admin@scalario.com';
    const password = 'admin123';
    const tenantId = 'd0a5e840-7d8d-4f14-8a4b-1c5c6d3b4e2a';

    console.log('Checking for existing user...');
    let userId;

    // First try to find the user
    const { data: { users }, error: listError } = await supabase.auth.admin.listUsers();

    if (listError) {
        console.error('Error listing users:', listError.message);
        return;
    }

    const existingUser = users.find(u => u.email === email);

    if (existingUser) {
        userId = existingUser.id;
        console.log('Found existing user:', userId);
    } else {
        console.log('User not found, creating...');
        const { data: userData, error: userError } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
        });

        if (userError) {
            console.error('Error creating user:', userError.message);
            return;
        }

        userId = userData.user.id;
        console.log('User created:', userId);
    }

    console.log('Creating tenant...');
    const { error: insertTenantError } = await supabase.from('tenants').upsert({
        id: tenantId,
        name: 'Demo Store',
    });

    if (insertTenantError) {
        console.error('Error inserting tenant:', insertTenantError.message);
    } else {
        console.log('Tenant "Demo Store" created.');
    }

    console.log('Linking user to tenant...');
    const { error: linkError } = await supabase.from('organization_members').upsert({
        user_id: userId,
        organization_id: tenantId,
        role: 'owner',
    });

    if (linkError) {
        console.error('Error linking user:', linkError.message);
    } else {
        console.log('User linked to tenant successfully.');
    }
}

setup();
