--  Database Project - Paris/Beauvais shuttle bus service
--  SQL operations on the database
--  File: 04_queries.sql
--  Run on a database that is already created and populated


--  A. INSERT OPERATIONS


--  OP-A1  Register a new flight.
--  It fires trg_generate_daily_flights: after this insert,
--  the 7 daily occurrences of the flight appear in dailyFlight
--  on their own.
--  Note: until trips are assigned to it, the 7 daily flights
--  temporarily break R3; the test flight is removed
--  by OP-B2, which brings the database back to its initial state.

INSERT INTO flight (flightCode, airline, destination, departureTime)
VALUES ('AF9001', 'Air France', 'Nice', '07:15:00');

-- check the effect of the trigger:
SELECT * FROM dailyFlight WHERE flightCode = 'AF9001';


--  OP-A2  Register a new trip.
--  It fires two triggers: trg_check_capacity (checks that the
--  occupied seats are within the capacity of the bus) and
--  trg_num_passengers (computes the derived value again).
--  It matches OP1 in the table of operations (Phase 3);
--  the check SELECT matches OP3.


INSERT INTO busTrip (flightCode, day, busCode, occupiedSeats)
VALUES ('AF9001', 'Tuesday', 'BUS001', 28);

-- check:
SELECT * FROM dailyFlight
 WHERE flightCode = 'AF9001' AND day = 'Tuesday';


--  OP-A2bis  Insert that BREAKS constraint R1.
--  It is only here to show that trg_check_capacity rejects the row.
--  Remove the comment to try it.

-- INSERT INTO busTrip (flightCode, day, busCode, occupiedSeats)
-- VALUES ('AF9001', 'Wednesday', 'BUS001', 999);
-- ERROR: Occupied seats (999) exceed the capacity of bus BUS001 (35 seats).


--  B. UPDATE AND DELETE OPERATIONS


--  OP-B1  Correct the occupied seats of an existing trip.
--  It fires trg_num_passengers, which realigns the derived value.
--  It matches OP2 in the table of operations (Phase 3).

UPDATE busTrip
   SET occupiedSeats = 33
 WHERE flightCode = 'AF9001'
   AND day        = 'Tuesday'
   AND busCode    = 'BUS001';

-- check:
SELECT * FROM dailyFlight
 WHERE flightCode = 'AF9001' AND day = 'Tuesday';


--  OP-B2  Delete a flight that is not operated any more.
--  Thanks to ON DELETE CASCADE, its 7 daily flights and all
--  the related trips disappear too.

DELETE FROM flight WHERE flightCode = 'AF9001';

-- check: both SELECTs return nothing
SELECT * FROM dailyFlight WHERE flightCode = 'AF9001';
SELECT * FROM busTrip     WHERE flightCode = 'AF9001';


--  C. QUERIES


--  OP-C1  The drivers who, on the same day, served flights
--  of ALL the airlines in the system.
--  We keep the pair (driver, day) for which there is no
--  flight whose airline was not served by that same
--  driver on that same day.


SELECT DISTINCT b1.driver, t1.day
FROM bus b1
JOIN busTrip t1 ON t1.busCode = b1.busCode
WHERE NOT EXISTS (
        SELECT *
        FROM flight f
        WHERE NOT EXISTS (
                SELECT *
                FROM busTrip  t2
                JOIN bus      b2 ON b2.busCode    = t2.busCode
                JOIN flight   f2 ON f2.flightCode = t2.flightCode
                WHERE b2.driver   = b1.driver
                  AND t2.day      = t1.day
                  AND f2.airline  = f.airline
              )
      )
ORDER BY b1.driver, t1.day;


--  OP-C2  The daily flights served by at least three different buses.

--  The condition "at least three" is written without counters.

SELECT df.flightCode, df.day, df.numPassengers
FROM dailyFlight df
WHERE EXISTS (
        SELECT *
        FROM busTrip t1
        WHERE t1.flightCode = df.flightCode
          AND t1.day        = df.day
          AND EXISTS (
                SELECT *
                FROM busTrip t2
                WHERE t2.flightCode = df.flightCode
                  AND t2.day        = df.day
                  AND t2.busCode    > t1.busCode
                  AND EXISTS (
                        SELECT *
                        FROM busTrip t3
                        WHERE t3.flightCode = df.flightCode
                          AND t3.day        = df.day
                          AND t3.busCode    > t2.busCode
                      )
              )
      )
ORDER BY df.numPassengers DESC;


--  OP-C3  The drivers who served all the destinations
--  reached by a given airline (here: Air France).
--  We select the driver for whom there is no
--  destination of the airline that he or she never served.


SELECT DISTINCT b1.driver
FROM bus b1
WHERE NOT EXISTS (
        SELECT *
        FROM flight f
        WHERE f.airline = 'Air France'
          AND NOT EXISTS (
                SELECT *
                FROM busTrip  t
                JOIN bus      b2 ON b2.busCode    = t.busCode
                JOIN flight   f2 ON f2.flightCode = t.flightCode
                WHERE f2.airline      = f.airline
                  AND f2.destination  = f.destination
                  AND b2.driver       = b1.driver
              )
      );



--  OP-C4  The daily flight that carries the highest number
--  of passengers.

--  The maximum is found without aggregate functions.
--  It reads numPassengers of all the 350 daily flights: same
--  access profile as OP4 (Phase 3).

SELECT df1.flightCode, df1.day, df1.numPassengers
FROM dailyFlight df1
WHERE NOT EXISTS (
        SELECT *
        FROM dailyFlight df2
        WHERE df2.numPassengers > df1.numPassengers
      );
