--  Database Project - Paris/Beauvais shuttle bus service
--  File: 00_run_all.sql
--  Rebuilds the whole database with a single command.

--  Usage (from the ROOT folder of the repository, on an empty database):
--      psql -d shuttle -f sql/00_run_all.sql
--  Then, for the eight operations:
--      psql -d shuttle -f sql/04_queries.sql

\set ON_ERROR_STOP on

-- Phase 4: types, tables, constraints, indexes
\ir 01_schema.sql

-- Phase 5: the triggers must exist BEFORE the data,
-- otherwise they do not fire while the data is loaded
\ir 02_triggers.sql

-- Phase 5: loading the data generated with Mockaroo
-- (the CSV paths are relative to the folder where psql is started)
\copy flight (flightCode, airline, destination, departureTime) FROM 'data/flight.csv' WITH (FORMAT csv, HEADER true)
\copy bus (busCode, driver, availableSeats) FROM 'data/bus.csv' WITH (FORMAT csv, HEADER true)

-- Phase 5: generation of the bus trips and testing
\ir 03_population.sql
