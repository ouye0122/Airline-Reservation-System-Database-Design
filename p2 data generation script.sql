DELETE FROM p2.passengers;
DELETE FROM p2.airports;
DELETE FROM p2.aircraft_types;
DELETE FROM p2.flights;
DELETE FROM p2.bookings;
DELETE FROM p2.booking_passenger;
DELETE FROM p2.seat_prices;

WITH unique_passengers AS (
    SELECT 
        country_code || '-' || substr(md5(random()::text), 1, 16) AS passport_id,
        substr(first_name, 1, 25) AS first_name,
        substr(last_name, 1, 25) AS last_name,
        left(substr(email, 1, 20) || row_number() OVER () || '-' || substr(md5(random()::text), 1, 8) || '@example.com', 25) AS email,
        substr(phone, 1, 20) AS phone,
        CURRENT_DATE + (random() * (365 * 5))::int * INTERVAL '1 day' AS passport_expiry_date
    FROM (
        SELECT 
            (faker_person()).*, 
            (ARRAY['US','CA','GB','FR','DE','JP'])[floor(random()*6 + 1)::int] AS country_code
        FROM generate_series(1,20700) AS f 
    ) AS f
)
INSERT INTO p2.passengers (passport_id, first_name, last_name, email, phone, passport_expiry_date)
SELECT 
    passport_id, 
    first_name, 
    last_name, 
    email, 		
    phone, 
    passport_expiry_date
FROM unique_passengers;

INSERT INTO p2.airports (airport_code, name, city, country, timezone) VALUES
('BOS', 'Logan International Airport', 'Boston', 'USA', 'America/New_York'),
('LHR', 'London Heathrow Airport', 'London', 'United Kingdom', 'Europe/London'),
('JNB', 'O.R. Tambo International Airport', 'Johannesburg', 'South Africa', 'Africa/Johannesburg'),
('NRT', 'Narita International Airport', 'Tokyo', 'Japan', 'Asia/Tokyo');

INSERT INTO p2.aircraft_types (
    registration_id, model, manufacturer, business_capacity, first_capacity, operation_cost_per_hour
) VALUES
('N123AA', 'Boeing 787', 'Boeing', 70, 30, 12000.00),
('N456BB', 'Airbus A350', 'Airbus', 70, 30, 11500.00);

WITH flight_schedule AS (
    SELECT * FROM (
        VALUES
            ('AF100', 'BOS', 'LHR', '2025-05-04'::date, time '18:00', interval '7 hours', 'N123AA', interval '1 week'),
            ('AF101', 'LHR', 'JNB', '2025-05-06'::date, time '09:00', interval '11 hours', 'N123AA', interval '1 week'),
            ('AF200', 'JNB', 'LHR', '2025-05-09'::date, time '12:00', interval '11 hours', 'N123AA', interval '1 week'),
            ('AF201', 'LHR', 'BOS', '2025-05-11'::date, time '18:00', interval '7 hours', 'N123AA', interval '1 week'),
            ('AF300', 'BOS', 'NRT', '2025-05-04'::date, time '13:00', interval '14 hours', 'N456BB', interval '1 week'),
            ('AF301', 'NRT', 'BOS', '2025-05-07'::date, time '16:00', interval '13 hours', 'N456BB', interval '1 week')
    ) AS f(flight_number, dep_code, arr_code, start_date, dep_time, duration, aircraft, freq)
),
flight_instances AS (
    SELECT
        f.flight_number,
        f.dep_code,
        f.arr_code,
        (f.date + f.dep_time)::timestamptz AT TIME ZONE dep.timezone AS departure_time,
        (f.date + f.dep_time + f.duration)::timestamptz AT TIME ZONE arr.timezone AS arrival_time,
        f.aircraft
    FROM (
        SELECT 
            fs.*, 
            gs.date 
        FROM flight_schedule fs,
             generate_series(fs.start_date, '2025-12-31', fs.freq) AS gs(date)
    ) f
    INNER JOIN p2.airports dep ON f.dep_code = dep.airport_code 
    INNER JOIN p2.airports arr ON f.arr_code = arr.airport_code 
)
INSERT INTO p2.flights (
    flight_number,
    departure_airport_code,
    arrival_airport_code,
    departure_time,
    arrival_time,
    aircraft_registration_id
)
SELECT
    flight_number,
    dep_code,
    arr_code,
    departure_time,
    arrival_time,
    aircraft
FROM flight_instances
WHERE departure_time BETWEEN '2025-05-01' AND '2025-12-31'

WITH ranked_flights AS (
    SELECT flight_id,
           ROW_NUMBER() OVER (ORDER BY departure_time) AS flight_rank
    FROM p2.flights
),
ranked_passengers AS (
    SELECT passport_id,
           ROW_NUMBER() OVER (ORDER BY passport_id) AS pax_rank
    FROM p2.passengers
    WHERE passport_id IS NOT NULL
    LIMIT 21000
),
assigned AS (
    SELECT
        rp.passport_id,
        rf.flight_id,
        ((rp.pax_rank - 1) / 100 + 1) AS flight_block,
        ((rp.pax_rank - 1) % 100 + 1) AS seat_rn
    FROM ranked_passengers rp
    JOIN ranked_flights rf
      ON ((rp.pax_rank - 1) / 100 + 1) = rf.flight_rank
),
with_seats AS (
    SELECT *,
        CASE 
            WHEN seat_rn <= 70 THEN 'business'
            ELSE 'first'
        END AS seat_class,
        CASE 
            WHEN seat_rn <= 70 THEN 'B' || LPAD(seat_rn::text, 2, '0')
            ELSE 'F' || LPAD((seat_rn - 70)::text, 2, '0')
        END AS seat_number
    FROM assigned
),
inserted_bookings AS (
    INSERT INTO p2.bookings (flight_id)
    SELECT flight_id
    FROM with_seats
    RETURNING reservation, flight_id
),
numbered_bookings AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY flight_id ORDER BY reservation) AS seat_rn
    FROM inserted_bookings
)
INSERT INTO p2.booking_passenger (
    reservation, passport_id, seat_number, seat_class
)
SELECT
    nb.reservation,
    ws.passport_id,
    ws.seat_number,
    ws.seat_class
FROM numbered_bookings nb
JOIN with_seats ws
  ON nb.flight_id = ws.flight_id AND nb.seat_rn = ws.seat_rn;


INSERT INTO p2.seat_prices (flight_number, seat_class, seat_price) VALUES
('AF100', 'business', 1250.00),
('AF100', 'first', 2500.00),
('AF101', 'business', 1250.00),
('AF101', 'first', 2500.00),
('AF200', 'business', 1250.00),
('AF200', 'first', 2500.00),
('AF201', 'business', 1250.00),
('AF201', 'first', 2500.00),
('AF300', 'business', 2000.00),
('AF300', 'first', 4000.00),
('AF301', 'business', 2000.00),
('AF301', 'first', 4000.00);

SELECT * FROM p2.passengers;
SELECT * FROM p2.airports;
SELECT * FROM p2.aircraft_types;
SELECT * FROM p2.flights ORDER BY departure_time;
SELECT * FROM p2.seat_prices;
SELECT * FROM p2.bookings;
SELECT * FROM p2.booking_passenger;