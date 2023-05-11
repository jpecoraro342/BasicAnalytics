'use strict';

const express = require('express');
const bodyParser = require('body-parser');
const { insertEvent, pool } = require('./queries');
require('express-async-errors');

// Constants
const PORT = 8080;
const HOST = '0.0.0.0';

// App
const app = express();

app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// Routes
app.get('/status', async (req, res) => {
  const result = await pool.query('SELECT NOW()');
  res.status(200).json({ result: result.rows });
});

app.post('/event', async (req, res) => {
  let data = req.body;

  console.log(data);

  const result = (await insertEvent(data)).rows[0];
  res.status(201).json({ event: result });
});

app.post('/events', async (req, res) => {
  let events = req.body.events;
  let system = req.body.system;

  if (system) {
    events = events.map(event => { return Object.assign(system, event)});
  }

  let results = await Promise.all(events.map(async (event) => {
    try {
      // TODO: add support for seperate system fields
      var event = (await insertEvent(event)).rows[0];
    } catch (err) {
      var error = err;
    }

    return { event, error };
  }));

  let successfulEvents = results
    .filter(event => !event.error)
    .map(event => event.event);

  let errors = results
    .filter(event => event.error)
    .map(event => event.error);

  res.status(200).json({
    ...(!req.query['low-data'] && {
      events: successfulEvents,
      errors: errors,
     }),
    successCount: successfulEvents.length,
    errorCount: errors.length,
  });
});

app.use((err, req, res, next) => {
  console.log(err);
  res.json({ error: err });
})

var server = app.listen(process.env.PORT || PORT, HOST, () => {
  console.log(`Running on http://${HOST}:${server.address().port}`);
});