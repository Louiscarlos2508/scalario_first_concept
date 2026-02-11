console.log('Starting debug script...');
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'http://127.0.0.1:54321';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function test() {
    console.log('Calling createUser...');
    const email = 'admin@scalario.com';
    const password = 'admin123';

    try {
        const { data, error } = await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
        });

        console.log('createUser returned.');
        if (error) {
            console.log('Full Error Object:', JSON.stringify(error, null, 2));
            console.log('Message:', error.message);
            console.log('Include check:', error.message.includes('already registered'));
        } else {
            console.log('User created successfully (unexpected for debug run).');
        }
    } catch (e) {
        console.error('Exception:', e);
    }
}

test();
