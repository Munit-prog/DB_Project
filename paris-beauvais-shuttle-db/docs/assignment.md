# Project text (English translation)

The domain of this project comes from **Exercise 1** of the Databases exam of
5 September 2011 (Computer Science, 9 ECTS, University of Udine). This is an
English translation of the whole exam text; the original is in Italian.

\---

## Databases exam – Computer Science 9 ECTS

*5 September 2011*

### Exercise 1

Consider the following relational schema of a database that contains the data
about the management of a shuttle bus service that connects the city of Paris
to Paris Beauvais airport in a specific week of the year (only for the route
Paris city – Paris Beauvais airport):

* *offreVolo(compagniaAerea, codiceVolo, destinazione, oraDecollo)*;
* *voloQuotidiano(codiceVolo, giorno)*;
* *bus(codiceBus, autista, postiDisponibili)*;
* *corsaBus(codiceVolo, giorno, codiceBus, postiOccupati)*.

> In this repository the schema is translated as: \*flight(airline, flightCode,
> destination, departureTime)\*, \*dailyFlight(flightCode, day)\*,
> \*bus(busCode, driver, availableSeats)\*,
> \*busTrip(flightCode, day, busCode, occupiedSeats)\*.

Assume that:

* every flight is uniquely identified by a suitable code (for example, the code
FR4984 identifies the Ryanair flight from Paris Beauvais to Venice at 10:45)
and is described by its destination (Venice), its planned departure time
(10:45) and the airline that offers it (Ryanair);
* every flight is repeated every day of the week (for example, the flight from
Paris Beauvais to Venice at 10:45, identified by the code FR4984, is operated
every day from Monday to Sunday);
* every shuttle bus is uniquely identified by a suitable code and is described
by its driver and by its number of available seats;
* every bus can make zero, one or more trips per day, also for different
airlines, but not more than one trip for a given flight;
* the passengers who must board a given flight on a certain day of the week are
taken to the airport by one or more buses;
* on every trip, a bus only carries passengers of one given flight (so, for
example, a given trip of a certain bus cannot carry both passengers of the
flight from Paris Beauvais to Venice and passengers of the flight from Paris
Beauvais to Bucharest).

First define the primary keys, any other candidate keys and, if there are any,
the foreign keys of the given relations. Then write suitable relational algebra
queries to find (without using the division operator, and using aggregate
functions only if necessary):

(a) the drivers who did not make any trip for (the flights of) the airline Air
France;

(b) the drivers who made at most two trips for (the flights of) the airline
Ryanair;

(c) the drivers who made trips for a superset of the airlines for which the
driver Dupont made trips.

### Exercise 2

With reference to Exercise 1, write suitable SQL queries to find what is asked
(using aggregate functions only if necessary).

### 

