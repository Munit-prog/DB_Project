
--  Database Project
--  Shuttle bus service  Paris city <-> Beauvais airport
--  Phase 4 - Physical design          (DBMS: PostgreSQL)
--  File: 01_schema.sql  -- types, tables, constraints and indexes



-- Drop script, so the database can be built again

-- Tables, triggers, constraints
DROP TABLE IF EXISTS busTrip, dailyFlight, bus, flight CASCADE;

-- Enumerated type
DROP TYPE  IF EXISTS weekday;

-- Domain type for the days of the week
CREATE TYPE weekday AS ENUM
  ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Flight offered by an airline (the departure is always Beauvais)
-- airline comes from merging the Airline entity in phase 3
CREATE TABLE flight (
    flightCode      VARCHAR(10) PRIMARY KEY,
    airline         VARCHAR(60) NOT NULL,
    destination     VARCHAR(60) NOT NULL,
    departureTime   TIME        NOT NULL,
    UNIQUE (airline, destination, departureTime)
);


-- Shuttle bus; driver comes from merging the Driver entity
-- during the restructuring step in phase 3
CREATE TABLE bus (
    busCode          VARCHAR(10) PRIMARY KEY,
    driver           VARCHAR(60) NOT NULL,
    availableSeats   SMALLINT    NOT NULL CHECK (availableSeats > 0)
);

-- Daily occurrence of a flight (weak entity of flight).
-- numPassengers is the DERIVED attribute = sum of occupiedSeats
-- of the trips of the (flight, day); it is kept up to date by the triggers (Phase 5).
CREATE TABLE dailyFlight (
    flightCode     VARCHAR(10)      NOT NULL,
    day            weekday          NOT NULL,
    numPassengers  INTEGER          NOT NULL DEFAULT 0
                                    CHECK (numPassengers >= 0),
    PRIMARY KEY (flightCode, day),
    FOREIGN KEY (flightCode) REFERENCES flight (flightCode)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Trip: a bus carries the passengers of a daily flight.
-- Key (flightCode, day, busCode): a bus makes at most one
-- trip for a given daily flight.
CREATE TABLE busTrip (
    flightCode     VARCHAR(10)      NOT NULL,
    day            weekday          NOT NULL,
    busCode        VARCHAR(10)      NOT NULL,
    occupiedSeats  SMALLINT         NOT NULL
                                    CHECK (occupiedSeats > 0),
    PRIMARY KEY (flightCode, day, busCode),
    FOREIGN KEY (flightCode, day)
        REFERENCES dailyFlight (flightCode, day)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (busCode)
        REFERENCES bus (busCode)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


--  Secondary indexes
--  (primary keys already have an automatic unique index)


-- Foreign key that PostgreSQL does not index: it is needed for the joins
-- bus <-> busTrip (all the operations "on the drivers") and for the
-- referential integrity checks when a bus is deleted.
CREATE INDEX idx_trip_bus      ON busTrip  (busCode);

-- Indexes evaluated and NOT created (reasons in the report, Phase 4):
--   flight(airline)               50 rows, a single page on disk
--   bus(driver)                   15 rows, a single page on disk
--   dailyFlight(numPassengers)    updated at every trip, used only by the report of the busiest flights

