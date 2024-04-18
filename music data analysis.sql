-- Queations- Easy level

-- 1. Who is the senior most employee based on job title?
-- 2. Which countries have the most Invoices?
-- 3. What are top 3 values of total invoice?
-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city 
--    we made the most money. Write a query that returns one city that has the highest sum of invoice totals. 
--    Return both the city name & sum of all invoice totals
-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--    Write a query that returns the person who has spent the most money.

-- 1. Who is the senior most employee based on job title?
SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;

-- 2. Which countries have the most Invoices?
SELECT billing_country, COUNT(*) AS total_count FROM invoice
GROUP BY billing_country
ORDER BY total_count DESC
LIMIT 1;

-- 3. What are top 3 values of total invoice?
SELECT * FROM invoice
ORDER BY total DESC
LIMIT 3;

-- 4. Which city has the best customers? We would like to throw a promotional Music Festival in the city 
--    we made the most money. Write a query that returns one city that has the highest sum of invoice totals.
--    Return both the city name & sum of all invoice totals 
SELECT billing_city, SUM(total) AS total_invoice_sum 
FROM invoice
GROUP BY billing_city
ORDER BY total_invoice_sum DESC 
LIMIT 1;

-- 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--    Write a query that returns the person who has spent the most money.
SELECT c.customer_id, c.first_name, c.last_name, SUM(i.total) AS Total_invoice 
from customer c 
JOIN invoice i ON c.customer_id=i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name 
ORDER BY Total_invoice DESC
LIMIT 1;




-- Questions- Moderate Level
-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--    Return your list ordered alphabetically by email starting with A
-- 2. Let's invite the artists who have written the most rock music in our dataset.  
--    Write a query that returns the Artist name and total track count of the top 10 rock bands
-- 3. Return all the track names that have a song length longer than the average song length. 
--    Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.


-- 1. Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--    Return your list ordered alphabetically by email starting with A.
	SELECT DISTINCT c.first_name, c.last_name, c.email FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    WHERE il.track_id IN (
		SELECT t.track_id
		FROM track t 
		JOIN genre g ON t.genre_id = g.genre_id
		WHERE g.name LIKE 'Rock'
    )
    ORDER BY c.email;

-- 2. Let's invite the artists who have written the most rock music in our dataset.  
--    Write a query that returns the Artist name and total track count of the top 10 rock bands
SELECT ar.name, (ar.artist_id) AS total_artist
FROM track t 
JOIN album al ON al.album_id = t.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
JOIN genre g ON g.genre_id = t.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY total_artist DESC
LIMIT 10;

-- 3. Return all the track names that have a song length longer than the average song length. 
--    Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) 
    FROM track
)
ORDER BY milliseconds DESC;


-- Question Set 3 – Advance
-- 1. Find how much amount spent by each customer on artists? 
--    Write a query to return customer name, artist name and total spent
-- 2. We want to find out the most popular music Genre for each country. We determine the 
--    most popular genre as the genre with the highest amount of purchases. Write a query 
--    that returns each country along with the top Genre. For countries where the maximum 
--    number of purchases is shared return all Genres
-- 3. Write a query that determines the customer that has spent the most on music for each 
--    country. Write a query that returns the country along with the top customer and how
--    much they spent. For countries where the top amount spent is shared, provide all 
--    customers who spent this amoun.


-- 1. Find how much amount spent by each customer on artists? 
--    Write a query to return customer name, artist name and total spent
WITH best_selling_artist AS (
	SELECT arr.artist_id, arr.name , SUM(ill.unit_price * ill.quantity) AS total_invoice
    FROM invoice_line ill 
    JOIN track tr ON ill.track_id = tr.track_id
    JOIN album alb ON tr.album_id = alb.album_id
    JOIN artist arr ON alb.artist_id = arr.artist_id
    GROUP BY arr.artist_id, arr.name
    ORDER BY total_invoice DESC
    LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.name,
		SUM(il.unit_price*il.quantity) AS total_amount
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album al ON t.album_id=al.album_id
JOIN best_selling_artist bsa ON bsa.artist_id = al.artist_id 
GROUP  BY c.customer_id,
		  c.first_name,
          c.last_name,
          bsa.name 
ORDER BY  total_amount desc;

-- 2. We want to find out the most popular music Genre for each country. We determine the 
--    most popular genre as the genre with the highest amount of purchases. Write a query 
--    that returns each country along with the top Genre. For countries where the maximum 
--    number of purchases is shared return all Genres
WITH cte AS(
	SELECT COUNT(quantity) AS total_purchase, c.country, g.name AS genre_type,
    ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(quantity) DESC) AS rowno
	FROM invoice_line il
	JOIN invoice i ON i.invoice_id = il.invoice_id
	JOIN customer c ON c.customer_id = i.customer_id
	JOIN track t ON t.track_id = il.track_id
	JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY 2,3
    ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM cte WHERE rowno <=1;

-- 3. Write a query that determines the customer that has spent the most on music for each 
--    country. Write a query that returns the country along with the top customer and how
--    much they spent. For countries where the top amount spent is shared, provide all 
--    customers who spent this amoun.
WITH RECURSIVE customer_with_country AS( 
	SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(i.total) AS total_spending
    FROM invoice i 
    JOIN customer c ON c.customer_id = i.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 4 ASC, 5 DESC
),
country_with_max_spending AS (
	SELECT billing_country, MAX(total_spending) AS Max_spending
    FROM customer_with_country
    GROUP BY billing_country
)
SELECT cc.billing_country, cc.first_name, cc.last_name, cc.total_spending
FROM customer_with_country cc
JOIN country_with_max_spending ms ON cc.billing_country = ms.billing_country
WHERE cc.total_spending = ms.Max_spending
ORDER BY 1;

-- Method 2

WITH customer_with_country AS (
	SELECT c.customer_id, c.first_name, c.last_name, i.billing_country, SUM(i.total) AS total_spending,
    ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(i.total) DESC) AS rowno
    FROM invoice i
    JOIN customer c ON i.customer_id = c.customer_id
    GROUP BY 1,2,3,4
    ORDER BY 4 ASC, 5 DESC
    )
    SELECT customer_with_country.* 
    FROM customer_with_country
    WHERE rowno <= 1;
    