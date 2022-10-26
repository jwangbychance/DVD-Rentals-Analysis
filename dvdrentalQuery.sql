-----------------------------
---- DVD Rental Analysis ----
-----------------------------

-- 1. Who are the customers that have rented a film?
SELECT DISTINCT c.first_name, c.last_name
FROM customer c
INNER JOIN rental r
ON c.customer_id = r.customer_id;

-- 2. Who are the customers that have spent more than 100?
SELECT c.customer_id, c.first_name, c.last_name, SUM(p.amount) AS amount_spent
FROM customer c
INNER JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING SUM(p.amount) > 100
ORDER BY amount_spent;

-- 3. What films are currently not in the inventory?
SELECT f.film_id, f.title, i.inventory_id
FROM film f
LEFT JOIN inventory i
ON f.film_id = i.film_id
WHERE i.inventory_id IS NULL
ORDER BY f.title;

-- 4. Which films have been rented for each customer?
SELECT DISTINCT c.first_name, c.last_name, f.title
FROM film f
INNER JOIN inventory i
ON f.film_id = i.film_id
INNER JOIN rental r
ON i.inventory_id = r.inventory_id
INNER JOIN customer c
ON r.customer_id = c.customer_id
ORDER BY c.first_name, c.last_name, f.title;

-- 5. How many films have been rented for each customer?
SELECT c.first_name, c.last_name, COUNT(f.title)
FROM film f
INNER JOIN inventory i
ON f.film_id = i.film_id
INNER JOIN rental r
ON i.inventory_id = r.inventory_id
INNER JOIN customer c
ON r.customer_id = c.customer_id
GROUP BY c.first_name, c.last_name
ORDER BY c.first_name, c.last_name;

-- 6. What are the top and least rented (in-demand) genres and what are their total sales?
WITH t1 AS (SELECT c.name AS genre, COUNT(cu.customer_id) AS in_demand
		    FROM category c
		    INNER JOIN film_category fc
		    ON c.category_id = fc.category_id
		    INNER JOIN film f
		    ON fc.film_id = f.film_id
		    INNER JOIN inventory i
		    ON f.film_id = i.film_id
		    INNER JOIN rental r
		    ON i.inventory_id = r.inventory_id
			INNER JOIN customer cu
			ON r.customer_id = cu.customer_id
		    GROUP BY c.name),
	 t2 AS (SELECT c.name AS genre, SUM(p.amount) AS total_sales
		    FROM category c
		    INNER JOIN film_category fc
		    ON c.category_id = fc.category_id
		    INNER JOIN film f
		    ON fc.film_id = f.film_id
		    INNER JOIN inventory i
		    ON f.film_id = i.film_id
		    INNER JOIN rental r
		    ON i.inventory_id = r.inventory_id
		    INNER JOIN payment p
		    ON r.rental_id = p.rental_id
		    GROUP BY c.name)

SELECT t1.genre, t1.in_demand, t2.total_sales
FROM t1
INNER JOIN t2
ON t1.genre = t2.genre
WHERE t1.in_demand IN
	(SELECT MAX(t1.in_demand) FROM t1)
OR t1.in_demand IN
	(SELECT MIN(t1.in_demand) FROM t1);

-- 7. How many distinct users have rented each genre?
SELECT cg.name AS name, COUNT(DISTINCT c.customer_id) AS users
FROM category cg
INNER JOIN film_category fc
ON cg.category_id = fc.category_id
INNER JOIN film f
ON fc.film_id = f.film_id
INNER JOIN inventory i 
ON f.film_id = i.film_id
INNER JOIN rental r
ON i.inventory_id = r.inventory_id
INNER JOIN customer c
ON r.customer_id = c.customer_id
GROUP BY name
ORDER BY users DESC;

-- 8. What is the average rental rate for each genre? (from the highest to the lowest)
SELECT c.name AS genre, ROUND(AVG(f.rental_rate), 2) AS average_rental_rate
FROM category c
INNER JOIN film_category fc
ON c.category_id = fc.category_id
INNER JOIN film f
ON fc.film_id = f.film_id
GROUP BY genre
ORDER BY average_rental_rate DESC;

-- 9. What is the customer base and total sales in each country? 
SELECT ct.country, COUNT(DISTINCT c.customer_id) AS customer_base, SUM(p.amount) AS total_sales
FROM country ct
INNER JOIN city cy
ON ct.country_id = cy.country_id 
INNER JOIN address a
ON cy.city_id = a.city_id
INNER JOIN customer c
ON a.address_id = c.address_id
INNER JOIN payment p
ON c.customer_id = p.customer_id
GROUP BY ct.country
ORDER BY customer_base DESC;

-- 10. Designate a value [Short, Medium, Long] based on the rental duration.
SELECT film_id, title,
CASE
	WHEN rental_duration < 5 THEN 'Short'
	WHEN rental_duration < 7 THEN 'Medium'
	ELSE 'Long'
END AS duration
FROM film
ORDER BY rental_duration;

-- 11. Who are the top 5 most popular actors?
SELECT a.first_name, a.last_name, COUNT(f.film_id) AS films_acted
FROM actor a
INNER JOIN film_actor fa
ON a.actor_id = fa.actor_id
INNER JOIN film f
ON fa.film_id = f.film_id
GROUP BY a.actor_id
ORDER BY films_acted DESC
LIMIT 5;

-- 12. What is the second most popular category?
WITH t1 AS (SELECT cg.name AS name, COUNT(DISTINCT c.customer_id) AS users
			FROM category cg
			INNER JOIN film_category fc
			ON cg.category_id = fc.category_id
			INNER JOIN film f
			ON fc.film_id = f.film_id
			INNER JOIN inventory i 
			ON f.film_id = i.film_id
			INNER JOIN rental r
			ON i.inventory_id = r.inventory_id
			INNER JOIN customer c
			ON r.customer_id = c.customer_id
			GROUP BY name)

SELECT name, users AS second_highest
FROM t1 
WHERE users IN
	(SELECT MAX(users) AS second_highest
	 FROM t1
	 WHERE users < (SELECT MAX(users) FROM t1)
);

-- 13. How many rented films were returned late, early, and on time?
SELECT 
CASE
WHEN f.rental_duration > EXTRACT(day FROM r.return_date - r.rental_date)
	THEN 'Film returned early'
WHEN f.rental_duration = EXTRACT(day FROM r.return_date - r.rental_date)
	THEN 'Film returned on time'
ELSE 'Film returned late'
END AS rental_status,
COUNT(f.film_id) AS total_films
FROM film f
INNER JOIN inventory i
ON f.film_id = i.film_id
INNER JOIN rental r
ON i.inventory_id = r.inventory_id
GROUP BY rental_status
ORDER BY total_films;

-- 14. Who are the top 5 customers per total sales and their details?
SELECT c.first_name || ' ' || c.last_name AS customer, c.email, a.address, a.phone, ct.city, cy.country, SUM(p.amount) AS total_sales
FROM payment p
INNER JOIN customer c
ON p.customer_id = c.customer_id
INNER JOIN address a
ON c.address_id = a.address_id
INNER JOIN city ct
ON a.city_id = ct.city_id
INNER JOIN country cy
ON ct.country_id = cy.country_id
GROUP BY c.customer_id, a.address_id, ct.city_id, cy.country_id
ORDER BY total_sales DESC
LIMIT 5;