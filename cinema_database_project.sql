CREATE SCHEMA theater;
CREATE SCHEMA booking;

CREATE TABLE theater.movies
(
	movie_id UUID PRIMARY KEY DEFAULT UUIDV7(),
	title VARCHAR(80) NOT NULL ,
	genre VARCHAR (30) NOT NULL,
	duration_mins INT CHECK (duration_mins > 0),
	rating VARCHAR (8) CHECK (rating IN ('U','UA','A')) NOT NULL,
	release_date DATE
);
SELECT * FROM theater.movies;

CREATE TABLE theater.screens
(
	screen_id UUID PRIMARY KEY DEFAULT UUIDV7(),
	screen_name VARCHAR(50) NOT NULL,
	total_seats INT CHECK (total_seats >0),
	screen_type VARCHAR (20) CHECK (screen_type IN ('2D','3D','4DX','IMAX'))
);
SELECT * FROM theater.screens;

CREATE TABLE theater.shows
(
	show_id UUID PRIMARY KEY DEFAULT UUIDV7(),
	movie_id UUID REFERENCES theater.movies(movie_id) ON DELETE RESTRICT,
	screen_id UUID REFERENCES theater.screens(screen_id) ON DELETE RESTRICT,
	show_time TIMESTAMPTZ NOT NULL,
	ticket_price NUMERIC (5,2) NOT NULL CHECK (ticket_price>0)
);
SELECT * FROM theater.shows;

CREATE TABLE booking.customers
(
	customer_id UUID PRIMARY KEY DEFAULT UUIDV7(),
	full_name VARCHAR (70) NOT NULL, 
	email VARCHAR(100) UNIQUE NOT NULL ,
	phone VARCHAR(15) NOT NULL,
	city VARCHAR(20) NOT NULL
);
SELECT * FROM booking.customers;

CREATE TABLE booking.tickets
(
	ticket_id UUID PRIMARY KEY DEFAULT UUIDV7(),
	show_id UUID REFERENCES theater.shows(show_id) ON DELETE RESTRICT,
	customer_id UUID REFERENCES booking.customers(customer_id) ON DELETE RESTRICT,
	seats_booked INT CHECK (seats_booked BETWEEN 1 AND 10), 
	total_amount INT CHECK (total_amount >=0),
	booking_status VARCHAR CHECK (booking_status IN('confirmed','pending','cancelled')),
	booked_at TIMESTAMPTZ NOT NULL
);
ALTER TABLE booking.tickets
ALTER COLUMN total_amount TYPE NUMERIC(10, 2);

SELECT * FROM booking.tickets;

SELECT m.title AS Movie_Title, m.rating, s.screen_name, s.screen_type, sh.show_time, sh.ticket_price
	FROM theater.shows sh
	INNER JOIN theater.screens s ON sh.screen_id=s.screen_id
	INNER JOIN theater.movies m ON sh.movie_id=m.movie_id
	WHERE sh.show_time > '2026-11-21 00:00:00+00'
ORDER BY sh.show_time ASC;

SELECT m.title AS Movie_Title, m.genre,SUM(t.seats_booked) AS Total_Seats_Sold,SUM(t.total_amount) AS Boxoffice_Revenue
	FROM theater.movies m
INNER JOIN theater.shows sh ON m.movie_id=sh.movie_id
INNER JOIN booking.tickets t ON sh.show_id=t.show_id
	WHERE t.booking_status='confirmed'
GROUP BY m.movie_id,m.title,m.genre
ORDER BY Boxoffice_Revenue DESC;

SELECT m.genre,SUM(t.seats_booked) AS confirmed_seats_sold
FROM theater.movies m
INNER JOIN theater.shows sh ON m.movie_id=sh.movie_id
INNER JOIN booking.tickets t ON sh.show_id=t.show_id
WHERE t.booking_status='confirmed'
GROUP BY m.genre
HAVING SUM(t.seats_booked) > 40
ORDER BY confirmed_seats_sold DESC;

SELECT m.title, m.genre, m.rating, m.release_date
FROM theater.movies m
LEFT JOIN theater.shows sh ON m.movie_id=sh.movie_id
WHERE sh.show_id IS NULL
ORDER BY m.release_date;

SELECT c.full_name AS Customer_Name, c.city, COUNT(t.ticket_id)AS confirmed_bookings, SUM(t.total_amount) AS total_spent
FROM booking.customers c 
INNER JOIN booking.tickets t ON c.customer_id=t.customer_id
WHERE t.booking_status = 'confirmed'
AND c.city IN ('Udaipur','Jaipur')
GROUP BY c.customer_id,customer_name,c.city
ORDER BY total_spent DESC
LIMIT 5 ;

SELECT ticket_id,show_id,seats_booked,total_amount,booking_status
FROM booking.tickets t
WHERE booking_status IN('pending','confirmed')
LIMIT 1;
UPDATE booking.tickets
SET
	booking_status='cancelled',
	total_amount=0.00
	WHERE ticket_id= '01a0f97b-4300-7497-9b83-499235ce8841'
	AND booking_status !='cancelled'
RETURNING ticket_id,show_id,seats_booked,total_amount,booking_status;
