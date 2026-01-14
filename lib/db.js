import { Pool } from 'pg';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}

const ssl =
  process.env.PGSSLMODE === 'disable'
    ? false
    : { rejectUnauthorized: false };

const pool = global.__pgPool || new Pool({ connectionString, ssl });

if (!global.__pgPool) {
  global.__pgPool = pool;
}

export default pool;
