
--  Database Project - Paris/Beauvais shuttle bus service
--  Phase 5 - Implementation : POPULATION
--  File: 03_population.sql
--  Run AFTER 01_schema.sql, 02_triggers.sql and the loading
--  of the two CSV files.


-- The data generated with Mockaroo (flight, bus) is loaded
-- by the two \copy commands in 00_run_all.sql.

-- dailyFlight is not filled by hand: the trigger
-- trg_generate_daily_flights fills it automatically (7 rows for each flight).
-- numPassengers is the derived attribute, the trigger trg_num_passengers computes it.

-- Fixed seed: the population can be reproduced.

SELECT setseed(0.42);


--  Step 1 - one trip for EVERY daily flight (350 rows).
--  It guarantees the mandatory participation (1,N) of the daily
--  flight in the trip relationship: no flight is left without a bus.

--  The sampling is inside a MATERIALIZED CTE.

WITH assignment AS MATERIALIZED (
    SELECT DISTINCT ON (df.flightCode, df.day)
           df.flightCode,
           df.day,
           b.busCode,
           b.availableSeats
    FROM dailyFlight df
    CROSS JOIN bus b
    ORDER BY df.flightCode, df.day, random()
)
INSERT INTO busTrip (flightCode, day, busCode, occupiedSeats)
SELECT flightCode,
       day,
       busCode,
       1 + floor(random() * availableSeats)::int
FROM assignment;



--  Step 2 - 350 more trips among the combinations not used yet, to reach 700

WITH sample AS MATERIALIZED (
    SELECT df.flightCode,
           df.day,
           b.busCode,
           b.availableSeats
    FROM dailyFlight df
    CROSS JOIN bus b
    WHERE NOT EXISTS (
            SELECT 1 FROM busTrip t
             WHERE t.flightCode = df.flightCode
               AND t.day        = df.day
               AND t.busCode    = b.busCode
          )
    ORDER BY random()
    LIMIT 350
)
INSERT INTO busTrip (flightCode, day, busCode, occupiedSeats)
SELECT flightCode,
       day,
       busCode,
       1 + floor(random() * availableSeats)::int
FROM sample;

--  Step 3 - Testing the population and the triggers
--  These are the checks mentioned in the report (Phase 5). Aggregate
--  functions are allowed here: these are not the project queries,
--  only checks on the generated data.

-- K1 (trigger 1 / R2): every flight has exactly 7 daily flights.
--     Expected: 0 rows.
SELECT flightCode, count(*) AS occurrences
FROM dailyFlight
GROUP BY flightCode
HAVING count(*) <> 7;

-- K2 (R3): daily flights left without any trip.
--     Expected: 0 rows.
SELECT df.flightCode, df.day
FROM dailyFlight df
WHERE NOT EXISTS (
        SELECT 1 FROM busTrip t
         WHERE t.flightCode = df.flightCode
           AND t.day        = df.day
      );

-- K3 (trigger 3 / DR1): stored value different from the sum
--     computed on the spot. Expected: 0 rows.
SELECT df.flightCode, df.day, df.numPassengers
FROM dailyFlight df
WHERE df.numPassengers <> COALESCE((
        SELECT SUM(t.occupiedSeats) FROM busTrip t
         WHERE t.flightCode = df.flightCode
           AND t.day        = df.day), 0);

-- K4: distribution of the generated loads (values reported in the report).
SELECT min(t.occupiedSeats)                     AS min_seats,
       max(t.occupiedSeats)                     AS max_seats,
       round(avg(t.occupiedSeats), 1)           AS avg_seats,
       max(round(100.0 * t.occupiedSeats / b.availableSeats))
                                                AS max_fill_pct
FROM busTrip t
JOIN bus b ON b.busCode = t.busCode;

SELECT max(numPassengers)             AS max_passengers_df,
       round(avg(numPassengers), 1)   AS avg_passengers_df
FROM dailyFlight;
