const { Client } = require('pg');

const connectionString = "postgresql://postgres:postgres@127.0.0.1:54322/postgres";

async function listTables() {
    const client = new Client({
        connectionString: connectionString,
    });

    try {
        await client.connect();
        const res = await client.query(`
      SELECT table_schema, table_name 
      FROM information_schema.tables 
      WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
      ORDER BY table_schema, table_name;
    `);
        console.log('Tables in database:');
        res.rows.forEach(row => console.log(`${row.table_schema}.${row.table_name}`));
    } catch (err) {
        console.error('Error listing tables:', err);
    } finally {
        await client.end();
    }
}

listTables();
