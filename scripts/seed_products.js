const { Client } = require('pg');

const connectionString = "postgresql://postgres:postgres@127.0.0.1:54322/postgres";

async function seedProducts() {
    const client = new Client({
        connectionString: connectionString,
    });

    try {
        await client.connect();
        console.log('Connected to PostgreSQL');

        // Get the first tenant
        const resTenant = await client.query('SELECT id FROM tenants LIMIT 1');
        if (resTenant.rows.length === 0) {
            console.log('No tenants found. Please run setup first.');
            return;
        }
        const tenantId = resTenant.rows[0].id;

        const products = [
            { name: 'Classic Burger', price: 12.50, category: 'Food' },
            { name: 'Cheese Pizza', price: 15.00, category: 'Food' },
            { name: 'Coca Cola', price: 2.50, category: 'Drinks' },
            { name: 'Iced Latte', price: 4.50, category: 'Drinks' },
            { name: 'Chocolate Muffin', price: 3.75, category: 'Bakery' },
        ];

        for (const p of products) {
            await client.query(
                'INSERT INTO products (name, price, category, tenant_id) VALUES ($1, $2, $3, $4) ON CONFLICT DO NOTHING',
                [p.name, p.price, p.category, tenantId]
            );
        }

        console.log('Demo products seeded successfully');
    } catch (err) {
        console.error('Error seeding products:', err);
    } finally {
        await client.end();
    }
}

seedProducts();
