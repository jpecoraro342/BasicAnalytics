const Pool = require('pg').Pool;

// Postgres
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASS || 'postgres',
  host: process.env.DB_HOST || 'db',
  database: process.env.DB_NAME || 'DB_NAME',
  port: 5432,
});

const insertEvent = async (event) => {
  return await pool.query(`
  INSERT INTO events (
    device_identifier,
    user_identifier,
    event_name,
    event_location,
    extras,
    event_time,
    experiments,
    app_name,
    app_version,
    app_build_number,
    device_type,
    os_version
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) 
  RETURNING id, event_name, event_time;
`, [event.device_identifier,
    event.user_identifier,
    event.event_name,
    event.event_location,
    event.extras,
    event.event_time,
    event.experiments,
    event.app_name,
    event.app_version,
    event.app_build_number,
    event.device_type,
    event.os_version]);
}

module.exports = { insertEvent, pool }