--
-- PostgreSQL database dump
--

\restrict CoXQiUwg4z2toKiFFCFiZgRuoPSwKEaO4ypcWkqeF44VBoEb7JbOPgnQUGmPGUa

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: weekday; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.weekday AS ENUM (
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
);


--
-- Name: check_capacity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_capacity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: generate_daily_flights(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_daily_flights() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    d weekday;
BEGIN
    FOREACH d IN ARRAY enum_range(NULL::weekday) LOOP
        INSERT INTO dailyFlight (flightCode, day)
        VALUES (NEW.flightCode, d);
    END LOOP;
    RETURN NULL;            -- AFTER trigger: the return value is ignored
END;
$$;


--
-- Name: update_num_passengers(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_num_passengers() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bus (
    buscode character varying(10) NOT NULL,
    driver character varying(60) NOT NULL,
    availableseats smallint NOT NULL,
    CONSTRAINT bus_availableseats_check CHECK ((availableseats > 0))
);


--
-- Name: bustrip; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bustrip (
    flightcode character varying(10) NOT NULL,
    day public.weekday NOT NULL,
    buscode character varying(10) NOT NULL,
    occupiedseats smallint NOT NULL,
    CONSTRAINT bustrip_occupiedseats_check CHECK ((occupiedseats > 0))
);


--
-- Name: dailyflight; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dailyflight (
    flightcode character varying(10) NOT NULL,
    day public.weekday NOT NULL,
    numpassengers integer DEFAULT 0 NOT NULL,
    CONSTRAINT dailyflight_numpassengers_check CHECK ((numpassengers >= 0))
);


--
-- Name: flight; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flight (
    flightcode character varying(10) NOT NULL,
    airline character varying(60) NOT NULL,
    destination character varying(60) NOT NULL,
    departuretime time without time zone NOT NULL
);


--
-- Data for Name: bus; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bus (buscode, driver, availableseats) FROM stdin;
BUS001	Homerus Cornwall	35
BUS002	Cheryl Etridge	40
BUS003	Troy Tingcomb	54
BUS004	Isa Horsewood	49
BUS005	Aida Gehrels	44
BUS006	Lark Domican	52
BUS007	Darrick Langwade	49
BUS008	Johnette Channon	36
BUS009	Mirna Billie	56
BUS010	Marielle Ditts	46
BUS011	Ray Brettoner	56
BUS012	Davidson Attewill	50
BUS013	Thatcher Shapland	54
BUS014	Michaeline McDowell	52
BUS015	Delmer Fray	37
\.


--
-- Data for Name: bustrip; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.bustrip (flightcode, day, buscode, occupiedseats) FROM stdin;
AF0001	Monday	BUS004	6
AF0001	Tuesday	BUS004	6
AF0001	Wednesday	BUS012	16
AF0001	Thursday	BUS001	29
AF0001	Friday	BUS002	31
AF0001	Saturday	BUS015	22
AF0001	Sunday	BUS009	46
AF0002	Monday	BUS011	38
AF0002	Tuesday	BUS003	34
AF0002	Wednesday	BUS014	51
AF0002	Thursday	BUS013	40
AF0002	Friday	BUS002	24
AF0002	Saturday	BUS007	27
AF0002	Sunday	BUS009	52
AF0003	Monday	BUS004	27
AF0003	Tuesday	BUS012	25
AF0003	Wednesday	BUS011	12
AF0003	Thursday	BUS002	36
AF0003	Friday	BUS008	1
AF0003	Saturday	BUS004	22
AF0003	Sunday	BUS008	10
AF0004	Monday	BUS012	50
AF0004	Tuesday	BUS008	30
AF0004	Wednesday	BUS004	42
AF0004	Thursday	BUS011	6
AF0004	Friday	BUS006	22
AF0004	Saturday	BUS001	35
AF0004	Sunday	BUS015	28
AF0005	Monday	BUS001	16
AF0005	Tuesday	BUS010	23
AF0005	Wednesday	BUS002	39
AF0005	Thursday	BUS014	12
AF0005	Friday	BUS014	50
AF0005	Saturday	BUS012	4
AF0005	Sunday	BUS007	48
AF0006	Monday	BUS010	45
AF0006	Tuesday	BUS011	12
AF0006	Wednesday	BUS009	28
AF0006	Thursday	BUS003	38
AF0006	Friday	BUS002	20
AF0006	Saturday	BUS005	40
AF0006	Sunday	BUS010	11
AF0007	Monday	BUS010	33
AF0007	Tuesday	BUS015	35
AF0007	Wednesday	BUS007	47
AF0007	Thursday	BUS014	3
AF0007	Friday	BUS013	12
AF0007	Saturday	BUS014	36
AF0007	Sunday	BUS009	42
AF0008	Monday	BUS004	8
AF0008	Tuesday	BUS011	34
AF0008	Wednesday	BUS013	51
AF0008	Thursday	BUS006	51
AF0008	Friday	BUS003	27
AF0008	Saturday	BUS007	38
AF0008	Sunday	BUS010	34
FR0001	Monday	BUS010	10
FR0001	Tuesday	BUS007	5
FR0001	Wednesday	BUS008	36
FR0001	Thursday	BUS010	15
FR0001	Friday	BUS014	2
FR0001	Saturday	BUS014	11
FR0001	Sunday	BUS001	24
FR0002	Monday	BUS013	49
FR0002	Tuesday	BUS014	31
FR0002	Wednesday	BUS005	41
FR0002	Thursday	BUS009	36
FR0002	Friday	BUS003	11
FR0002	Saturday	BUS015	1
FR0002	Sunday	BUS010	44
FR0003	Monday	BUS014	15
FR0003	Tuesday	BUS008	26
FR0003	Wednesday	BUS011	36
FR0003	Thursday	BUS013	5
FR0003	Friday	BUS004	46
FR0003	Saturday	BUS014	16
FR0003	Sunday	BUS005	27
FR0004	Monday	BUS004	26
FR0004	Tuesday	BUS003	16
FR0004	Wednesday	BUS007	35
FR0004	Thursday	BUS010	18
FR0004	Friday	BUS013	38
FR0004	Saturday	BUS015	13
FR0004	Sunday	BUS007	19
FR0005	Monday	BUS010	37
FR0005	Tuesday	BUS010	26
FR0005	Wednesday	BUS005	41
FR0005	Thursday	BUS005	28
FR0005	Friday	BUS004	22
FR0005	Saturday	BUS008	15
FR0005	Sunday	BUS013	51
FR0006	Monday	BUS013	50
FR0006	Tuesday	BUS011	14
FR0006	Wednesday	BUS005	35
FR0006	Thursday	BUS006	37
FR0006	Friday	BUS010	35
FR0006	Saturday	BUS009	24
FR0006	Sunday	BUS010	28
FR0007	Monday	BUS009	28
FR0007	Tuesday	BUS004	16
FR0007	Wednesday	BUS005	34
FR0007	Thursday	BUS006	44
FR0007	Friday	BUS009	5
FR0007	Saturday	BUS006	48
FR0007	Sunday	BUS015	28
FR0008	Monday	BUS005	20
FR0008	Tuesday	BUS014	8
FR0008	Wednesday	BUS014	43
FR0008	Thursday	BUS015	33
FR0008	Friday	BUS005	23
FR0008	Saturday	BUS005	21
FR0008	Sunday	BUS015	25
FR0009	Monday	BUS001	26
FR0009	Tuesday	BUS015	30
FR0009	Wednesday	BUS001	14
FR0009	Thursday	BUS015	1
FR0009	Friday	BUS002	31
FR0009	Saturday	BUS013	35
FR0009	Sunday	BUS009	31
FR0010	Monday	BUS003	37
FR0010	Tuesday	BUS015	3
FR0010	Wednesday	BUS012	2
FR0010	Thursday	BUS008	1
FR0010	Friday	BUS008	2
FR0010	Saturday	BUS001	9
FR0010	Sunday	BUS008	23
FR0011	Monday	BUS002	17
FR0011	Tuesday	BUS007	26
FR0011	Wednesday	BUS006	51
FR0011	Thursday	BUS014	23
FR0011	Friday	BUS010	32
FR0011	Saturday	BUS013	27
FR0011	Sunday	BUS014	18
FR0012	Monday	BUS015	26
FR0012	Tuesday	BUS008	18
FR0012	Wednesday	BUS011	26
FR0012	Thursday	BUS008	31
FR0012	Friday	BUS006	5
FR0012	Saturday	BUS010	3
FR0012	Sunday	BUS009	47
FR0013	Monday	BUS009	28
FR0013	Tuesday	BUS007	13
FR0013	Wednesday	BUS012	7
FR0013	Thursday	BUS009	32
FR0013	Friday	BUS001	22
FR0013	Saturday	BUS010	40
FR0013	Sunday	BUS001	3
FR0014	Monday	BUS011	14
FR0014	Tuesday	BUS011	28
FR0014	Wednesday	BUS001	1
FR0014	Thursday	BUS014	7
FR0014	Friday	BUS010	31
FR0014	Saturday	BUS004	36
FR0014	Sunday	BUS014	32
U20001	Monday	BUS013	3
U20001	Tuesday	BUS014	21
U20001	Wednesday	BUS007	42
U20001	Thursday	BUS009	51
U20001	Friday	BUS004	36
U20001	Saturday	BUS003	35
U20001	Sunday	BUS014	40
U20002	Monday	BUS010	9
U20002	Tuesday	BUS008	31
U20002	Wednesday	BUS003	52
U20002	Thursday	BUS001	18
U20002	Friday	BUS006	39
U20002	Saturday	BUS006	51
U20002	Sunday	BUS004	47
U20003	Monday	BUS002	16
U20003	Tuesday	BUS009	13
U20003	Wednesday	BUS003	21
U20003	Thursday	BUS008	34
U20003	Friday	BUS007	16
U20003	Saturday	BUS011	4
U20003	Sunday	BUS006	17
U20004	Monday	BUS006	49
U20004	Tuesday	BUS009	55
U20004	Wednesday	BUS003	20
U20004	Thursday	BUS005	22
U20004	Friday	BUS007	42
U20004	Saturday	BUS001	12
U20004	Sunday	BUS012	12
U20005	Monday	BUS007	12
U20005	Tuesday	BUS001	12
U20005	Wednesday	BUS014	15
U20005	Thursday	BUS008	15
U20005	Friday	BUS014	38
U20005	Saturday	BUS015	1
U20005	Sunday	BUS001	6
U20006	Monday	BUS011	15
U20006	Tuesday	BUS011	50
U20006	Wednesday	BUS006	9
U20006	Thursday	BUS001	12
U20006	Friday	BUS002	25
U20006	Saturday	BUS007	11
U20006	Sunday	BUS011	35
U20007	Monday	BUS009	27
U20007	Tuesday	BUS002	15
U20007	Wednesday	BUS005	35
U20007	Thursday	BUS008	31
U20007	Friday	BUS009	34
U20007	Saturday	BUS003	28
U20007	Sunday	BUS002	30
U20008	Monday	BUS011	35
U20008	Tuesday	BUS004	43
U20008	Wednesday	BUS007	18
U20008	Thursday	BUS006	2
U20008	Friday	BUS002	6
U20008	Saturday	BUS002	11
U20008	Sunday	BUS001	11
U20009	Monday	BUS008	19
U20009	Tuesday	BUS010	10
U20009	Wednesday	BUS014	51
U20009	Thursday	BUS003	20
U20009	Friday	BUS015	29
U20009	Saturday	BUS005	41
U20009	Sunday	BUS010	15
U20010	Monday	BUS003	7
U20010	Tuesday	BUS007	11
U20010	Wednesday	BUS003	50
U20010	Thursday	BUS012	11
U20010	Friday	BUS012	32
U20010	Saturday	BUS010	16
U20010	Sunday	BUS006	3
U20011	Monday	BUS015	35
U20011	Tuesday	BUS013	32
U20011	Wednesday	BUS004	28
U20011	Thursday	BUS013	45
U20011	Friday	BUS009	5
U20011	Saturday	BUS012	18
U20011	Sunday	BUS008	3
VY0001	Monday	BUS013	22
VY0001	Tuesday	BUS014	49
VY0001	Wednesday	BUS003	40
VY0001	Thursday	BUS006	32
VY0001	Friday	BUS002	18
VY0001	Saturday	BUS006	31
VY0001	Sunday	BUS014	7
VY0002	Monday	BUS011	20
VY0002	Tuesday	BUS002	35
VY0002	Wednesday	BUS011	39
VY0002	Thursday	BUS014	47
VY0002	Friday	BUS015	14
VY0002	Saturday	BUS013	39
VY0002	Sunday	BUS012	50
VY0003	Monday	BUS004	39
VY0003	Tuesday	BUS001	34
VY0003	Wednesday	BUS004	32
VY0003	Thursday	BUS006	46
VY0003	Friday	BUS015	10
VY0003	Saturday	BUS005	11
VY0003	Sunday	BUS009	29
VY0004	Monday	BUS011	56
VY0004	Tuesday	BUS011	20
VY0004	Wednesday	BUS004	9
VY0004	Thursday	BUS015	35
VY0004	Friday	BUS015	12
VY0004	Saturday	BUS015	1
VY0004	Sunday	BUS007	36
VY0005	Monday	BUS011	31
VY0005	Tuesday	BUS005	16
VY0005	Wednesday	BUS007	43
VY0005	Thursday	BUS004	26
VY0005	Friday	BUS004	24
VY0005	Saturday	BUS005	5
VY0005	Sunday	BUS007	2
VY0006	Monday	BUS009	38
VY0006	Tuesday	BUS012	37
VY0006	Wednesday	BUS003	14
VY0006	Thursday	BUS001	8
VY0006	Friday	BUS012	35
VY0006	Saturday	BUS013	21
VY0006	Sunday	BUS005	33
VY0007	Monday	BUS004	20
VY0007	Tuesday	BUS013	6
VY0007	Wednesday	BUS004	39
VY0007	Thursday	BUS009	5
VY0007	Friday	BUS011	3
VY0007	Saturday	BUS014	46
VY0007	Sunday	BUS002	6
VY0008	Monday	BUS001	26
VY0008	Tuesday	BUS004	5
VY0008	Wednesday	BUS003	21
VY0008	Thursday	BUS015	23
VY0008	Friday	BUS015	6
VY0008	Saturday	BUS006	5
VY0008	Sunday	BUS002	6
VY0009	Monday	BUS012	17
VY0009	Tuesday	BUS009	16
VY0009	Wednesday	BUS005	35
VY0009	Thursday	BUS007	46
VY0009	Friday	BUS008	35
VY0009	Saturday	BUS011	47
VY0009	Sunday	BUS010	11
VY0010	Monday	BUS013	3
VY0010	Tuesday	BUS006	41
VY0010	Wednesday	BUS008	26
VY0010	Thursday	BUS002	18
VY0010	Friday	BUS011	39
VY0010	Saturday	BUS014	1
VY0010	Sunday	BUS008	11
W60001	Monday	BUS013	37
W60001	Tuesday	BUS006	3
W60001	Wednesday	BUS004	43
W60001	Thursday	BUS001	20
W60001	Friday	BUS011	33
W60001	Saturday	BUS007	23
W60001	Sunday	BUS007	47
W60002	Monday	BUS010	2
W60002	Tuesday	BUS014	20
W60002	Wednesday	BUS008	14
W60002	Thursday	BUS011	42
W60002	Friday	BUS002	28
W60002	Saturday	BUS002	16
W60002	Sunday	BUS011	42
W60003	Monday	BUS011	35
W60003	Tuesday	BUS005	38
W60003	Wednesday	BUS011	32
W60003	Thursday	BUS006	51
W60003	Friday	BUS012	4
W60003	Saturday	BUS001	6
W60003	Sunday	BUS005	40
W60004	Monday	BUS009	26
W60004	Tuesday	BUS013	10
W60004	Wednesday	BUS004	43
W60004	Thursday	BUS008	1
W60004	Friday	BUS003	19
W60004	Saturday	BUS001	17
W60004	Sunday	BUS003	40
W60005	Monday	BUS006	32
W60005	Tuesday	BUS007	48
W60005	Wednesday	BUS009	40
W60005	Thursday	BUS010	38
W60005	Friday	BUS010	14
W60005	Saturday	BUS010	14
W60005	Sunday	BUS011	41
W60006	Monday	BUS006	32
W60006	Tuesday	BUS004	35
W60006	Wednesday	BUS006	33
W60006	Thursday	BUS010	38
W60006	Friday	BUS012	45
W60006	Saturday	BUS011	32
W60006	Sunday	BUS014	28
W60007	Monday	BUS015	6
W60007	Tuesday	BUS007	16
W60007	Wednesday	BUS007	2
W60007	Thursday	BUS003	33
W60007	Friday	BUS008	9
W60007	Saturday	BUS005	12
W60007	Sunday	BUS004	17
W60006	Wednesday	BUS002	17
U20006	Saturday	BUS012	27
FR0010	Thursday	BUS004	24
AF0002	Saturday	BUS006	15
VY0004	Tuesday	BUS014	28
AF0008	Friday	BUS004	42
FR0004	Wednesday	BUS011	20
FR0008	Tuesday	BUS012	27
U20011	Saturday	BUS011	52
VY0001	Thursday	BUS011	19
VY0003	Tuesday	BUS008	4
FR0008	Monday	BUS013	24
U20004	Monday	BUS001	15
W60003	Friday	BUS010	8
VY0009	Saturday	BUS015	26
AF0001	Thursday	BUS012	6
U20001	Wednesday	BUS009	13
FR0001	Tuesday	BUS006	41
FR0010	Tuesday	BUS001	26
U20007	Saturday	BUS009	24
U20003	Thursday	BUS003	52
FR0001	Tuesday	BUS014	37
AF0008	Sunday	BUS004	47
FR0012	Tuesday	BUS011	52
VY0009	Thursday	BUS008	21
FR0007	Wednesday	BUS011	20
AF0003	Wednesday	BUS005	42
FR0011	Monday	BUS006	24
FR0010	Saturday	BUS009	40
FR0004	Sunday	BUS006	25
VY0006	Wednesday	BUS012	27
W60006	Monday	BUS009	16
VY0008	Saturday	BUS002	18
W60003	Saturday	BUS007	44
AF0002	Friday	BUS015	2
U20010	Thursday	BUS005	25
AF0001	Tuesday	BUS005	12
U20011	Thursday	BUS003	23
FR0003	Friday	BUS012	44
VY0005	Wednesday	BUS012	2
AF0008	Monday	BUS014	19
AF0008	Thursday	BUS012	7
FR0006	Wednesday	BUS010	19
VY0004	Sunday	BUS005	2
W60005	Tuesday	BUS015	23
VY0001	Tuesday	BUS015	2
VY0003	Monday	BUS009	47
VY0003	Wednesday	BUS009	46
VY0002	Thursday	BUS009	52
AF0001	Saturday	BUS008	12
FR0013	Tuesday	BUS001	26
FR0004	Friday	BUS005	29
U20006	Friday	BUS005	19
VY0010	Sunday	BUS002	12
FR0014	Friday	BUS009	26
W60003	Friday	BUS014	27
W60004	Wednesday	BUS011	51
AF0001	Saturday	BUS007	29
VY0002	Thursday	BUS008	18
VY0001	Tuesday	BUS012	20
W60006	Sunday	BUS015	37
W60004	Friday	BUS004	40
FR0006	Saturday	BUS005	37
W60005	Wednesday	BUS008	21
AF0006	Wednesday	BUS008	21
U20010	Wednesday	BUS009	47
AF0004	Saturday	BUS011	28
U20011	Sunday	BUS013	22
U20007	Monday	BUS005	38
AF0002	Saturday	BUS001	5
VY0002	Tuesday	BUS008	9
FR0014	Wednesday	BUS015	21
FR0001	Sunday	BUS009	22
FR0013	Wednesday	BUS014	31
VY0002	Wednesday	BUS006	26
VY0006	Friday	BUS006	10
FR0002	Tuesday	BUS008	12
AF0007	Saturday	BUS001	25
AF0005	Monday	BUS008	15
VY0006	Friday	BUS014	44
U20004	Wednesday	BUS002	12
AF0005	Friday	BUS012	34
FR0003	Friday	BUS014	27
U20008	Thursday	BUS013	47
VY0004	Wednesday	BUS008	18
FR0012	Monday	BUS004	42
U20004	Friday	BUS011	19
AF0001	Friday	BUS006	34
U20005	Saturday	BUS011	30
FR0002	Friday	BUS010	43
VY0001	Tuesday	BUS009	53
AF0005	Sunday	BUS008	11
VY0009	Thursday	BUS005	28
U20011	Monday	BUS009	15
FR0003	Tuesday	BUS010	43
U20003	Monday	BUS005	39
VY0002	Friday	BUS010	40
U20008	Monday	BUS012	8
FR0001	Friday	BUS004	17
W60001	Friday	BUS007	14
W60003	Tuesday	BUS006	46
VY0007	Thursday	BUS010	37
FR0009	Sunday	BUS013	5
AF0001	Friday	BUS013	16
W60004	Monday	BUS002	16
W60001	Thursday	BUS002	39
VY0006	Wednesday	BUS001	21
AF0007	Saturday	BUS015	28
U20006	Wednesday	BUS002	16
U20011	Friday	BUS003	12
U20011	Monday	BUS005	21
VY0008	Friday	BUS014	3
FR0009	Tuesday	BUS001	29
FR0011	Friday	BUS009	32
AF0002	Wednesday	BUS003	50
FR0002	Saturday	BUS009	30
FR0012	Friday	BUS007	21
FR0005	Tuesday	BUS014	5
VY0009	Monday	BUS014	51
FR0013	Saturday	BUS005	42
FR0013	Tuesday	BUS004	9
U20003	Saturday	BUS003	1
AF0007	Monday	BUS008	36
VY0010	Monday	BUS011	27
U20001	Friday	BUS002	36
FR0003	Saturday	BUS002	28
FR0004	Thursday	BUS009	5
U20009	Wednesday	BUS015	18
FR0006	Tuesday	BUS008	11
VY0004	Saturday	BUS006	16
FR0010	Sunday	BUS011	14
W60001	Thursday	BUS008	18
VY0009	Saturday	BUS013	17
VY0005	Saturday	BUS015	11
VY0001	Friday	BUS010	9
AF0008	Saturday	BUS003	28
FR0002	Monday	BUS004	8
AF0006	Saturday	BUS008	23
U20001	Monday	BUS007	3
U20005	Tuesday	BUS008	17
FR0007	Monday	BUS013	23
FR0004	Saturday	BUS002	30
U20006	Tuesday	BUS006	34
AF0008	Wednesday	BUS008	13
W60004	Thursday	BUS004	31
W60002	Sunday	BUS008	15
AF0002	Tuesday	BUS011	23
FR0004	Monday	BUS007	39
U20007	Wednesday	BUS015	3
VY0007	Wednesday	BUS014	36
VY0002	Friday	BUS003	44
VY0008	Tuesday	BUS014	15
U20003	Tuesday	BUS014	3
U20011	Friday	BUS013	17
FR0013	Thursday	BUS013	13
FR0012	Tuesday	BUS014	18
U20008	Friday	BUS008	24
VY0006	Tuesday	BUS013	27
VY0003	Sunday	BUS006	33
AF0008	Wednesday	BUS002	17
FR0002	Friday	BUS014	21
U20002	Thursday	BUS009	32
VY0003	Saturday	BUS001	33
FR0013	Sunday	BUS005	17
W60006	Friday	BUS010	37
U20004	Wednesday	BUS001	17
U20002	Tuesday	BUS015	32
W60007	Sunday	BUS010	24
VY0006	Thursday	BUS015	29
VY0006	Monday	BUS004	14
FR0012	Wednesday	BUS009	13
W60001	Monday	BUS006	21
FR0004	Saturday	BUS005	2
FR0002	Sunday	BUS012	18
FR0011	Thursday	BUS002	16
AF0008	Tuesday	BUS013	54
VY0010	Sunday	BUS009	7
FR0014	Wednesday	BUS003	36
AF0006	Saturday	BUS014	48
VY0004	Wednesday	BUS002	4
AF0006	Thursday	BUS013	6
U20010	Monday	BUS008	18
U20002	Friday	BUS010	1
FR0006	Tuesday	BUS014	7
VY0005	Thursday	BUS006	52
FR0004	Tuesday	BUS013	7
FR0009	Saturday	BUS007	32
AF0001	Friday	BUS015	34
U20007	Saturday	BUS011	44
FR0004	Saturday	BUS011	53
VY0001	Sunday	BUS009	15
FR0007	Thursday	BUS002	39
VY0008	Friday	BUS009	30
U20005	Sunday	BUS015	31
VY0008	Wednesday	BUS006	27
W60005	Wednesday	BUS005	3
W60002	Wednesday	BUS011	38
FR0003	Monday	BUS002	13
FR0005	Saturday	BUS015	30
FR0006	Saturday	BUS012	33
U20001	Saturday	BUS011	1
FR0007	Saturday	BUS013	28
AF0004	Friday	BUS014	20
U20003	Friday	BUS010	3
FR0012	Tuesday	BUS002	15
FR0011	Saturday	BUS006	32
AF0007	Tuesday	BUS007	1
VY0007	Monday	BUS015	33
U20010	Sunday	BUS010	34
U20005	Tuesday	BUS007	9
FR0004	Thursday	BUS012	40
W60006	Thursday	BUS007	21
FR0011	Sunday	BUS010	3
FR0012	Thursday	BUS007	19
FR0014	Saturday	BUS012	30
FR0007	Sunday	BUS010	29
VY0003	Thursday	BUS011	4
FR0011	Wednesday	BUS013	33
AF0005	Saturday	BUS002	32
AF0007	Saturday	BUS004	26
U20004	Friday	BUS006	37
FR0009	Saturday	BUS002	18
U20005	Saturday	BUS007	31
FR0009	Friday	BUS001	13
U20001	Sunday	BUS005	42
W60004	Tuesday	BUS009	35
FR0014	Tuesday	BUS012	30
U20005	Thursday	BUS010	3
VY0002	Thursday	BUS003	33
VY0003	Thursday	BUS013	50
U20004	Tuesday	BUS013	34
AF0001	Friday	BUS008	3
VY0005	Wednesday	BUS014	35
AF0001	Thursday	BUS002	10
FR0005	Tuesday	BUS006	31
FR0002	Friday	BUS006	34
U20001	Tuesday	BUS003	53
U20009	Saturday	BUS002	23
W60001	Sunday	BUS006	24
AF0004	Thursday	BUS010	15
U20008	Sunday	BUS014	20
U20002	Monday	BUS005	2
FR0011	Sunday	BUS004	9
VY0005	Sunday	BUS006	2
FR0009	Monday	BUS009	2
AF0008	Sunday	BUS011	10
FR0009	Wednesday	BUS008	32
U20004	Thursday	BUS007	39
FR0003	Tuesday	BUS006	17
AF0002	Saturday	BUS002	23
FR0004	Saturday	BUS008	20
VY0001	Saturday	BUS011	24
VY0010	Friday	BUS009	7
U20002	Wednesday	BUS002	35
VY0009	Thursday	BUS015	32
AF0008	Monday	BUS001	28
FR0009	Sunday	BUS011	3
VY0010	Friday	BUS001	29
FR0007	Wednesday	BUS007	26
FR0004	Wednesday	BUS015	35
AF0003	Wednesday	BUS002	36
FR0011	Monday	BUS008	11
U20009	Sunday	BUS014	50
U20006	Monday	BUS002	37
FR0001	Monday	BUS002	23
W60003	Tuesday	BUS013	14
U20004	Sunday	BUS014	36
U20011	Sunday	BUS014	33
FR0010	Sunday	BUS004	31
U20002	Tuesday	BUS010	22
FR0005	Friday	BUS002	32
VY0010	Saturday	BUS006	48
FR0014	Thursday	BUS006	21
U20007	Friday	BUS002	27
FR0014	Saturday	BUS015	2
U20011	Monday	BUS011	43
W60007	Wednesday	BUS014	52
U20001	Saturday	BUS014	51
U20003	Friday	BUS012	26
U20003	Saturday	BUS004	19
FR0012	Sunday	BUS013	39
U20007	Friday	BUS008	6
VY0007	Sunday	BUS012	13
U20003	Sunday	BUS013	52
VY0006	Saturday	BUS014	42
FR0002	Tuesday	BUS004	27
FR0013	Wednesday	BUS010	6
FR0007	Monday	BUS005	11
W60004	Wednesday	BUS007	35
VY0006	Sunday	BUS012	9
FR0003	Monday	BUS013	13
FR0011	Monday	BUS005	35
U20009	Sunday	BUS015	7
U20007	Thursday	BUS001	22
VY0004	Saturday	BUS001	30
AF0005	Tuesday	BUS004	1
AF0001	Wednesday	BUS001	26
W60001	Saturday	BUS006	46
FR0003	Saturday	BUS005	44
AF0005	Tuesday	BUS003	24
AF0004	Tuesday	BUS002	29
VY0009	Tuesday	BUS008	15
AF0005	Sunday	BUS002	28
FR0010	Tuesday	BUS005	42
U20005	Tuesday	BUS005	40
VY0003	Saturday	BUS009	12
FR0005	Tuesday	BUS009	42
AF0007	Wednesday	BUS014	2
VY0004	Tuesday	BUS004	31
FR0013	Tuesday	BUS010	3
W60001	Sunday	BUS003	11
FR0001	Friday	BUS015	29
FR0007	Sunday	BUS002	15
FR0008	Wednesday	BUS007	12
AF0007	Friday	BUS011	53
U20008	Sunday	BUS006	2
W60001	Monday	BUS011	48
U20010	Thursday	BUS004	1
AF0003	Sunday	BUS011	17
U20009	Thursday	BUS014	48
FR0010	Friday	BUS006	35
U20004	Friday	BUS005	13
FR0011	Friday	BUS008	12
VY0004	Thursday	BUS003	26
U20003	Sunday	BUS011	18
FR0006	Sunday	BUS012	5
U20002	Saturday	BUS014	10
FR0009	Wednesday	BUS007	31
U20009	Wednesday	BUS001	23
U20011	Wednesday	BUS013	41
VY0005	Sunday	BUS005	21
FR0002	Thursday	BUS014	17
VY0004	Sunday	BUS002	39
FR0010	Saturday	BUS002	20
VY0005	Tuesday	BUS015	30
FR0003	Wednesday	BUS012	29
FR0013	Sunday	BUS015	16
W60001	Wednesday	BUS003	24
FR0013	Sunday	BUS002	38
FR0007	Wednesday	BUS014	39
VY0003	Thursday	BUS002	38
U20001	Wednesday	BUS002	29
VY0010	Sunday	BUS014	25
VY0010	Tuesday	BUS004	22
FR0013	Monday	BUS008	13
AF0002	Sunday	BUS005	28
VY0007	Saturday	BUS012	23
FR0002	Monday	BUS005	33
VY0008	Sunday	BUS013	11
VY0008	Friday	BUS003	40
\.


--
-- Data for Name: dailyflight; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.dailyflight (flightcode, day, numpassengers) FROM stdin;
AF0001	Monday	6
AF0001	Sunday	46
AF0002	Monday	38
AF0002	Thursday	40
AF0003	Monday	27
AF0003	Tuesday	25
AF0003	Thursday	36
AF0003	Friday	1
AF0003	Saturday	22
AF0002	Friday	26
AF0001	Tuesday	18
AF0001	Saturday	63
AF0002	Wednesday	101
AF0002	Tuesday	57
AF0001	Friday	118
AF0001	Thursday	45
AF0002	Saturday	70
AF0003	Wednesday	90
AF0001	Wednesday	42
AF0002	Sunday	80
AF0004	Monday	50
AF0004	Wednesday	42
AF0004	Sunday	28
AF0005	Wednesday	39
AF0005	Thursday	12
AF0006	Monday	45
AF0006	Tuesday	12
AF0006	Friday	20
AF0006	Sunday	11
AF0007	Thursday	3
AF0007	Sunday	42
FR0001	Wednesday	36
FR0001	Thursday	15
FR0001	Saturday	11
FR0002	Wednesday	41
FR0003	Thursday	5
FR0003	Sunday	27
FR0005	Monday	37
FR0005	Wednesday	41
FR0005	Thursday	28
FR0005	Sunday	51
FR0006	Monday	50
FR0006	Thursday	37
FR0006	Friday	35
FR0007	Tuesday	16
FR0007	Friday	5
FR0008	Thursday	33
FR0008	Friday	23
FR0008	Saturday	21
FR0008	Sunday	25
FR0009	Thursday	1
FR0010	Monday	37
FR0010	Wednesday	2
FR0011	Tuesday	26
FR0012	Saturday	3
FR0013	Friday	22
FR0014	Monday	14
FR0014	Sunday	32
U20001	Thursday	51
U20002	Sunday	47
U20003	Wednesday	21
U20004	Saturday	12
U20005	Monday	12
U20005	Wednesday	15
U20005	Friday	38
U20006	Thursday	12
U20006	Sunday	35
U20007	Tuesday	15
U20007	Sunday	30
U20008	Tuesday	43
U20008	Wednesday	18
U20008	Saturday	11
U20009	Monday	19
U20009	Tuesday	10
U20009	Friday	29
U20010	Tuesday	11
U20010	Friday	32
U20010	Saturday	16
U20011	Tuesday	32
VY0001	Monday	22
VY0001	Wednesday	40
VY0002	Monday	20
VY0002	Saturday	39
VY0002	Sunday	50
VY0003	Friday	10
VY0004	Monday	56
VY0004	Friday	12
VY0005	Monday	31
VY0005	Friday	24
VY0007	Tuesday	6
VY0007	Friday	3
VY0008	Monday	26
VY0008	Thursday	23
VY0009	Wednesday	35
VY0009	Friday	35
VY0009	Sunday	11
VY0010	Wednesday	26
VY0010	Thursday	18
W60001	Tuesday	3
W60002	Monday	2
W60002	Tuesday	20
W60002	Thursday	42
W60002	Friday	28
W60002	Saturday	16
W60003	Monday	35
W60003	Wednesday	32
W60003	Thursday	51
W60003	Sunday	40
W60004	Saturday	17
W60004	Sunday	40
W60005	Monday	32
W60005	Thursday	38
W60005	Friday	14
W60005	Saturday	14
W60005	Sunday	41
W60006	Tuesday	35
W60006	Saturday	32
W60007	Monday	6
W60007	Tuesday	16
W60007	Thursday	33
W60007	Friday	9
W60007	Saturday	12
W60006	Wednesday	50
U20006	Saturday	38
FR0010	Thursday	25
AF0008	Friday	69
FR0008	Tuesday	35
U20011	Saturday	70
VY0001	Thursday	51
VY0003	Tuesday	38
FR0008	Monday	44
U20004	Monday	64
U20003	Thursday	86
FR0001	Tuesday	83
FR0004	Sunday	44
W60006	Monday	48
VY0008	Saturday	23
W60003	Saturday	50
U20011	Thursday	68
AF0008	Thursday	58
FR0006	Wednesday	54
W60005	Tuesday	71
VY0003	Monday	86
VY0003	Wednesday	78
FR0004	Friday	67
U20006	Friday	44
FR0014	Friday	57
W60003	Friday	39
W60006	Sunday	65
W60004	Friday	59
AF0006	Wednesday	49
U20010	Wednesday	97
AF0004	Saturday	63
U20007	Monday	65
VY0002	Tuesday	44
FR0001	Sunday	46
VY0002	Wednesday	65
AF0005	Monday	31
VY0006	Friday	89
AF0005	Friday	84
FR0003	Friday	117
U20008	Thursday	49
FR0012	Monday	68
VY0001	Tuesday	124
U20003	Monday	55
U20008	Monday	43
W60001	Friday	47
VY0007	Thursday	42
W60004	Monday	42
VY0006	Wednesday	62
U20006	Wednesday	25
FR0009	Tuesday	59
FR0002	Saturday	31
FR0012	Friday	26
VY0009	Monday	68
FR0013	Saturday	82
AF0007	Monday	69
VY0010	Monday	30
U20001	Friday	72
W60001	Thursday	77
VY0009	Saturday	90
VY0005	Saturday	16
VY0001	Friday	27
AF0008	Saturday	66
U20001	Monday	6
U20006	Tuesday	84
W60004	Thursday	32
W60002	Sunday	57
FR0004	Monday	65
U20007	Wednesday	38
VY0007	Wednesday	75
VY0002	Friday	98
VY0008	Tuesday	20
U20003	Tuesday	16
U20011	Friday	34
FR0013	Thursday	45
U20008	Friday	30
VY0006	Tuesday	64
VY0003	Sunday	62
AF0008	Wednesday	81
U20002	Thursday	50
W60006	Friday	82
U20004	Wednesday	49
W60007	Sunday	41
VY0006	Thursday	37
VY0006	Monday	52
FR0012	Wednesday	39
FR0002	Sunday	62
FR0011	Thursday	39
AF0008	Tuesday	88
FR0014	Wednesday	58
AF0006	Saturday	111
VY0004	Wednesday	31
AF0006	Thursday	44
U20010	Monday	25
U20002	Friday	40
FR0006	Tuesday	32
VY0005	Thursday	78
FR0004	Tuesday	23
U20007	Saturday	96
VY0001	Sunday	22
FR0007	Thursday	83
U20005	Sunday	37
VY0008	Wednesday	48
W60005	Wednesday	64
W60002	Wednesday	52
FR0005	Saturday	45
FR0006	Saturday	94
FR0007	Saturday	76
AF0004	Friday	42
FR0012	Tuesday	103
FR0011	Saturday	59
AF0007	Tuesday	36
VY0007	Monday	53
U20010	Sunday	37
FR0004	Thursday	63
W60006	Thursday	59
FR0012	Thursday	50
FR0011	Wednesday	84
AF0005	Saturday	36
AF0007	Saturday	115
FR0009	Saturday	85
U20005	Saturday	62
FR0009	Friday	44
U20001	Sunday	82
W60004	Tuesday	45
FR0014	Tuesday	58
U20005	Thursday	18
VY0002	Thursday	150
U20004	Tuesday	89
VY0005	Wednesday	80
FR0002	Friday	109
U20001	Tuesday	74
U20009	Saturday	64
AF0004	Thursday	21
U20002	Monday	11
FR0011	Sunday	30
FR0009	Monday	28
AF0008	Sunday	91
U20004	Thursday	61
FR0003	Tuesday	86
FR0004	Saturday	118
VY0001	Saturday	55
U20002	Wednesday	87
VY0009	Thursday	127
AF0008	Monday	55
FR0009	Sunday	39
VY0010	Friday	75
FR0004	Wednesday	90
U20006	Monday	52
FR0001	Monday	33
W60003	Tuesday	98
U20004	Sunday	48
U20011	Sunday	58
FR0010	Sunday	68
U20002	Tuesday	85
FR0005	Friday	54
VY0010	Saturday	49
FR0014	Thursday	28
FR0014	Saturday	68
U20011	Monday	114
W60007	Wednesday	54
U20001	Saturday	87
U20003	Friday	45
U20003	Saturday	24
FR0012	Sunday	86
U20007	Friday	67
VY0007	Sunday	19
VY0006	Saturday	63
FR0002	Tuesday	70
FR0013	Wednesday	44
FR0007	Monday	62
W60004	Wednesday	129
VY0006	Sunday	42
FR0003	Monday	41
FR0011	Monday	87
U20009	Sunday	72
U20007	Thursday	53
VY0004	Saturday	47
W60001	Saturday	69
FR0003	Saturday	88
AF0005	Tuesday	48
AF0004	Tuesday	59
VY0009	Tuesday	31
AF0005	Sunday	87
FR0010	Tuesday	71
U20005	Tuesday	78
VY0003	Saturday	56
FR0005	Tuesday	104
AF0007	Wednesday	49
VY0004	Tuesday	79
FR0013	Tuesday	51
W60001	Sunday	82
FR0001	Friday	48
FR0007	Sunday	72
FR0008	Wednesday	55
AF0007	Friday	65
U20008	Sunday	33
W60001	Monday	106
U20010	Thursday	37
AF0003	Sunday	27
U20009	Thursday	68
FR0010	Friday	37
U20004	Friday	111
FR0011	Friday	76
VY0004	Thursday	61
U20003	Sunday	87
FR0006	Sunday	33
U20002	Saturday	61
FR0009	Wednesday	77
U20009	Wednesday	92
U20011	Wednesday	69
VY0005	Sunday	25
FR0002	Thursday	53
VY0004	Sunday	77
FR0010	Saturday	69
VY0005	Tuesday	46
FR0003	Wednesday	65
W60001	Wednesday	67
FR0013	Sunday	74
FR0007	Wednesday	119
VY0003	Thursday	138
U20001	Wednesday	84
VY0010	Sunday	55
VY0010	Tuesday	63
FR0013	Monday	41
VY0007	Saturday	69
FR0002	Monday	90
VY0008	Sunday	17
VY0008	Friday	79
\.


--
-- Data for Name: flight; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flight (flightcode, airline, destination, departuretime) FROM stdin;
VY0001	Vueling	Copenhagen	07:26:41
VY0002	Vueling	Lisbon	18:09:32
VY0003	Vueling	Dublin	16:53:05
AF0001	Air France	Athens	08:07:47
U20001	easyJet	Dublin	07:17:41
AF0002	Air France	Copenhagen	17:59:21
AF0003	Air France	Amsterdam	15:51:42
U20002	easyJet	Rome	12:33:06
W60001	Wizz Air	Stockholm	07:33:05
FR0001	Ryanair	Berlin	19:10:26
AF0004	Air France	Stockholm	09:18:50
W60002	Wizz Air	Budapest	09:00:42
FR0002	Ryanair	Barcelona	20:35:37
VY0004	Vueling	Stockholm	12:16:16
FR0003	Ryanair	Lisbon	21:56:55
U20003	easyJet	Vienna	19:24:27
VY0005	Vueling	Vienna	12:34:57
VY0006	Vueling	Rome	06:23:39
FR0004	Ryanair	Budapest	12:19:22
FR0005	Ryanair	Milan	07:14:11
VY0007	Vueling	Vienna	06:42:27
AF0005	Air France	Milan	14:02:06
U20004	easyJet	Vienna	20:47:05
AF0006	Air France	Barcelona	19:10:45
FR0006	Ryanair	Rome	17:02:37
U20005	easyJet	Prague	16:27:09
U20006	easyJet	Vienna	13:55:30
W60003	Wizz Air	Copenhagen	16:56:39
AF0007	Air France	Berlin	18:29:36
VY0008	Vueling	Copenhagen	11:32:45
U20007	easyJet	Warsaw	07:23:58
FR0007	Ryanair	Stockholm	11:00:40
VY0009	Vueling	Lisbon	20:22:12
FR0008	Ryanair	Rome	21:03:05
FR0009	Ryanair	Warsaw	16:26:21
U20008	easyJet	Berlin	09:58:26
W60004	Wizz Air	Stockholm	21:36:50
W60005	Wizz Air	Athens	21:52:17
U20009	easyJet	Barcelona	21:05:12
FR0010	Ryanair	Madrid	12:31:56
FR0011	Ryanair	Athens	10:10:53
W60006	Wizz Air	Copenhagen	07:34:52
W60007	Wizz Air	Barcelona	07:46:05
AF0008	Air France	Copenhagen	16:54:21
FR0012	Ryanair	Barcelona	10:59:15
VY0010	Vueling	Copenhagen	06:20:54
FR0013	Ryanair	Madrid	17:16:06
U20010	easyJet	Madrid	10:51:34
U20011	easyJet	Stockholm	21:15:38
FR0014	Ryanair	Prague	11:20:45
\.


--
-- Name: bus bus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bus
    ADD CONSTRAINT bus_pkey PRIMARY KEY (buscode);


--
-- Name: bustrip bustrip_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bustrip
    ADD CONSTRAINT bustrip_pkey PRIMARY KEY (flightcode, day, buscode);


--
-- Name: dailyflight dailyflight_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dailyflight
    ADD CONSTRAINT dailyflight_pkey PRIMARY KEY (flightcode, day);


--
-- Name: flight flight_airline_destination_departuretime_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flight
    ADD CONSTRAINT flight_airline_destination_departuretime_key UNIQUE (airline, destination, departuretime);


--
-- Name: flight flight_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flight
    ADD CONSTRAINT flight_pkey PRIMARY KEY (flightcode);


--
-- Name: idx_trip_bus; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_trip_bus ON public.bustrip USING btree (buscode);


--
-- Name: bustrip trg_check_capacity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_check_capacity BEFORE INSERT OR UPDATE ON public.bustrip FOR EACH ROW EXECUTE FUNCTION public.check_capacity();


--
-- Name: flight trg_generate_daily_flights; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_generate_daily_flights AFTER INSERT ON public.flight FOR EACH ROW EXECUTE FUNCTION public.generate_daily_flights();


--
-- Name: bustrip trg_num_passengers; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_num_passengers AFTER INSERT OR DELETE OR UPDATE ON public.bustrip FOR EACH ROW EXECUTE FUNCTION public.update_num_passengers();


--
-- Name: bustrip bustrip_buscode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bustrip
    ADD CONSTRAINT bustrip_buscode_fkey FOREIGN KEY (buscode) REFERENCES public.bus(buscode) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: bustrip bustrip_flightcode_day_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bustrip
    ADD CONSTRAINT bustrip_flightcode_day_fkey FOREIGN KEY (flightcode, day) REFERENCES public.dailyflight(flightcode, day) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dailyflight dailyflight_flightcode_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dailyflight
    ADD CONSTRAINT dailyflight_flightcode_fkey FOREIGN KEY (flightcode) REFERENCES public.flight(flightcode) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict CoXQiUwg4z2toKiFFCFiZgRuoPSwKEaO4ypcWkqeF44VBoEb7JbOPgnQUGmPGUa

