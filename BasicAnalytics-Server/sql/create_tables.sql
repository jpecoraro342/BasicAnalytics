CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  device_identifier TEXT,
  user_identifier TEXT,
  event_name TEXT,
  event_location TEXT,
  extras JSONB,
  event_time TIMESTAMP,
  experiments TEXT[],
  app_name TEXT,
  app_version TEXT,
  app_build_number TEXT,
  device_type TEXT,
  os_version TEXT
);

CREATE INDEX IF NOT EXISTS events_idx ON events (device_identifier, user_identifier, event_name, event_location, event_time, app_name);
