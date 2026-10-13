--  Database Project - Paris/Beauvais shuttle bus service
--  Phase 5 - Implementation : TRIGGERS
--  File: 02_triggers.sql
--  Run AFTER 01_schema.sql and BEFORE the population



--  Trigger 1  (from R2)
--  Every flight that is inserted exists on all seven days of the
--  week: the 7 daily occurrences are generated automatically
--  (weak entity dailyFlight).

CREATE OR REPLACE FUNCTION generate_daily_flights()
RETURNS TRIGGER AS $$
DECLARE
    d weekday;
BEGIN
    FOREACH d IN ARRAY enum_range(NULL::weekday) LOOP
        INSERT INTO dailyFlight (flightCode, day)
        VALUES (NEW.flightCode, d);
    END LOOP;
    RETURN NULL;            -- AFTER trigger: the return value is ignored
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_generate_daily_flights ON flight;
CREATE TRIGGER trg_generate_daily_flights
AFTER INSERT ON flight
FOR EACH ROW EXECUTE FUNCTION generate_daily_flights();



--  Trigger 2  (from R1)
--  Stops a trip from carrying more passengers than the
--  capacity of the bus that makes it (constraint between two tables).


CREATE OR REPLACE FUNCTION check_capacity()
RETURNS TRIGGER AS $$
DECLARE
    capacity SMALLINT;
BEGIN
    SELECT availableSeats INTO capacity
      FROM bus
     WHERE busCode = NEW.busCode;

    IF NEW.occupiedSeats > capacity THEN
        RAISE EXCEPTION
          'Occupied seats (%) exceed the capacity of bus % (% seats).',
          NEW.occupiedSeats, NEW.busCode, capacity;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_check_capacity ON busTrip;
CREATE TRIGGER trg_check_capacity
BEFORE INSERT OR UPDATE ON busTrip
FOR EACH ROW EXECUTE FUNCTION check_capacity();



--  Trigger 3  (from DR1)
--  Keeps the derived attribute up to date:
--  dailyFlight.numPassengers = SUM(occupiedSeats)
--  over the trips of the (flight, day).


CREATE OR REPLACE FUNCTION update_num_passengers()
RETURNS TRIGGER AS $$
BEGIN
    -- "old" row touched by DELETE / UPDATE
    IF (TG_OP = 'DELETE' OR TG_OP = 'UPDATE') THEN
        UPDATE dailyFlight
           SET numPassengers = COALESCE((
                   SELECT SUM(occupiedSeats) FROM busTrip
                    WHERE flightCode = OLD.flightCode
                      AND day        = OLD.day), 0)
         WHERE flightCode = OLD.flightCode
           AND day        = OLD.day;
    END IF;

    -- "new" row touched by INSERT / UPDATE
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
        UPDATE dailyFlight
           SET numPassengers = COALESCE((
                   SELECT SUM(occupiedSeats) FROM busTrip
                    WHERE flightCode = NEW.flightCode
                      AND day        = NEW.day), 0)
         WHERE flightCode = NEW.flightCode
           AND day        = NEW.day;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_num_passengers ON busTrip;
CREATE TRIGGER trg_num_passengers
AFTER INSERT OR UPDATE OR DELETE ON busTrip
FOR EACH ROW EXECUTE FUNCTION update_num_passengers();
