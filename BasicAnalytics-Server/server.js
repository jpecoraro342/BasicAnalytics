'use strict';

const express = require('express');
const bodyParser = require('body-parser');
const Pool = require('pg').Pool;

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Postgres
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASS || 'postgres',
  host: process.env.DB_HOST || 'db',
  database: process.env.DB_NAME || 'DB_NAME',
  port: 5432,
});

// Routes
app.get('/status', (req, res) => {
  pool.query('SELECT NOW()', (err, results) => {
    res.json({ 'status': err || results.rows });
  });
});

app.post('/event', (req, res) => {
  let data = req.body[0];

  pool.query(`
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
`, [data.device_identifier,
    data.user_identifier,
    data.event_name,
    data.event_location,
    data.extras,
    data.event_time,
    data.experiments,
    data.app_name,
    data.app_version,
    data.app_build_number,
    data.device_type,
    data.os_version],
    (error, results) => {
      if (error) {
        res.json({ 'error': error });
      }

      const result = results.rows[0];
      res.status(201).json({ result });
    })
});

var server = app.listen(process.env.PORT || PORT, HOST, () => {
  console.log(`Running on http://${HOST}:${server.address().port}`);
});