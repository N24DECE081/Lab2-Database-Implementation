-- MySQL Sakila sample queries; run in the separate sakila database.

-- Confirm the important sample tables exist and contain data.
SELECT 'actor' AS table_name, COUNT(*) AS row_count FROM actor
UNION ALL SELECT 'film', COUNT(*) FROM film
UNION ALL SELECT 'rental', COUNT(*) FROM rental;

-- JOIN: films and their categories.
SELECT f.film_id, f.title, c.name AS category
FROM film AS f
JOIN film_category AS fc ON fc.film_id = f.film_id
JOIN category AS c ON c.category_id = fc.category_id
ORDER BY f.film_id
LIMIT 20;

-- LEFT JOIN + aggregation: every category and number of films.
SELECT c.category_id, c.name, COUNT(fc.film_id) AS film_count
FROM category AS c
LEFT JOIN film_category AS fc ON fc.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY film_count DESC, c.name;

-- Subquery: customers who have never rented a film.
SELECT c.customer_id, c.first_name, c.last_name
FROM customer AS c
WHERE NOT EXISTS (
    SELECT 1 FROM rental AS r WHERE r.customer_id = c.customer_id
)
ORDER BY c.customer_id;
