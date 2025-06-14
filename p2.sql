DROP TABLE IF EXISTS p2.airports;
DROP TABLE IF EXISTS p2.aircraft_types;
DROP TABLE IF EXISTS p2.flights;
DROP TABLE IF EXISTS p2.passengers;
DROP TABLE IF EXISTS p2.bookings;
DROP TABLE IF EXISTS p2.seat_prices;
DROP TABLE IF EXISTS p2.booking_passenger;

CREATE TABLE p2.airports (
    airport_code CHAR(3) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    city VARCHAR(20) NOT NULL,
    country VARCHAR(20) NOT NULL,
    timezone VARCHAR(30) NOT NULL
);

CREATE TABLE p2.aircraft_types (
    registration_id VARCHAR(10) PRIMARY KEY,
    model VARCHAR(20) NOT NULL,
    manufacturer VARCHAR(20),
    business_capacity SMALLINT,
    first_capacity SMALLINT,
    operation_cost_per_hour DECIMAL(8, 2)
);

CREATE TABLE p2.flights (
    flight_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    flight_number VARCHAR(10) NOT NULL,
    departure_airport_code CHAR(3) NOT NULL,
    arrival_airport_code CHAR(3) NOT NULL,
    departure_time TIMESTAMP WITH TIME ZONE NOT NULL,
    arrival_time TIMESTAMP WITH TIME ZONE NOT NULL,
    aircraft_registration_id VARCHAR(10) NOT NULL,
    FOREIGN KEY (departure_airport_code) REFERENCES p2.airports(airport_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (arrival_airport_code) REFERENCES p2.airports(airport_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (aircraft_registration_id) REFERENCES p2.aircraft_types(registration_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (flight_number, departure_time)  
);

CREATE TABLE p2.passengers (
    passport_id VARCHAR(25) PRIMARY KEY,
    first_name VARCHAR(25) NOT NULL,
    last_name VARCHAR(25) NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    phone VARCHAR(20),
    passport_expiry_date DATE
);

CREATE TABLE p2.bookings (
    reservation INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    flight_id INT NOT NULL, 
    booking_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_booking_flight
        FOREIGN KEY (flight_id) REFERENCES p2.flights(flight_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE p2.seat_prices (
    flight_number VARCHAR(10) NOT NULL,
    seat_class VARCHAR(10) CHECK (seat_class IN ('business', 'first')) NOT NULL,
    seat_price DECIMAL(6, 2) NOT NULL,
    PRIMARY KEY (flight_number, seat_class)
);

CREATE TABLE p2.booking_passenger (
    reservation BIGINT,
    passport_id VARCHAR(25),
    seat_number VARCHAR(10) NOT NULL,
    seat_class VARCHAR(10) CHECK (seat_class IN ('business', 'first')) NOT NULL,
    PRIMARY KEY (reservation, passport_id),
    FOREIGN KEY (reservation) REFERENCES p2.bookings(reservation)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (passport_id) REFERENCES p2.passengers(passport_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);



SELECT * FROM pg_timezone_names ORDER BY name;