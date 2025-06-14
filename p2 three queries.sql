--Will I make money?
SELECT 
    f.flight_number,
    f.departure_time,
    COUNT(bp.passport_id) AS seats_filled,
    SUM(
        CASE 
            WHEN bp.seat_class = 'business' THEN sp_business.seat_price
            WHEN bp.seat_class = 'first' THEN sp_first.seat_price
        END
    ) AS total_revenue,
    at.operation_cost_per_hour * EXTRACT(EPOCH FROM (f.arrival_time - f.departure_time)) / 3600 AS total_cost,
    SUM(
        CASE 
            WHEN bp.seat_class = 'business' THEN sp_business.seat_price
            WHEN bp.seat_class = 'first' THEN sp_first.seat_price
        END
    ) - (at.operation_cost_per_hour * EXTRACT(EPOCH FROM (f.arrival_time - f.departure_time)) / 3600) AS profit
FROM p2.booking_passenger bp
INNER JOIN p2.bookings b ON bp.reservation = b.reservation
INNER JOIN p2.flights f ON b.flight_id = f.flight_id
INNER JOIN p2.aircraft_types at ON f.aircraft_registration_id = at.registration_id
LEFT JOIN p2.seat_prices sp_business ON f.flight_number = sp_business.flight_number AND sp_business.seat_class = 'business'
LEFT JOIN p2.seat_prices sp_first ON f.flight_number = sp_first.flight_number AND sp_first.seat_class = 'first'
GROUP BY f.flight_number, f.departure_time, f.arrival_time, at.operation_cost_per_hour, at.registration_id;

--How many seats are filled or remaining on a particular flight?
SELECT 
    f.flight_number,
    f.departure_time,
    COUNT(bp.passport_id) AS seats_filled,
    at.business_capacity + at.first_capacity AS total_seats,
    (at.business_capacity + at.first_capacity) - COUNT(bp.passport_id) AS seats_remaining
FROM p2.flights f
INNER JOIN p2.aircraft_types at ON f.aircraft_registration_id = at.registration_id
LEFT JOIN p2.bookings b ON f.flight_id = b.flight_id
LEFT JOIN p2.booking_passenger bp ON b.reservation = bp.reservation
WHERE f.flight_number = 'AF100'
  AND DATE(f.departure_time) = '2025-05-04'
GROUP BY f.flight_number, f.departure_time, at.business_capacity, at.first_capacity;

--Departure and arrival times in local time zones
SELECT 
    f.flight_number,
    f.departure_time AT TIME ZONE da.timezone AS local_departure_time,
    f.arrival_time AT TIME ZONE aa.timezone AS local_arrival_time
FROM p2.flights f
INNER JOIN p2.airports da ON f.departure_airport_code = da.airport_code
INNER JOIN p2.airports aa ON f.arrival_airport_code = aa.airport_code
WHERE f.flight_number = 'AF100'
  AND DATE(f.departure_time) = '2025-05-04';
