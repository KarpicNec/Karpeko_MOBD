-- Задание 1 (про 3 таблицы): 
SELECT p.title AS "Товар", c.name AS "Категория", s.store_name AS "Продавец"
FROM products p 
JOIN categories c ON c.id = p.category_id
JOIN sellers s ON s.id = p.seller_id
LIMIT 20;
-- Задание 2 (про LEFT JOIN): 
SELECT p.title AS "Товар", r.id
FROM products p
LEFT JOIN reviews r ON r.product_id = p.id
WHERE r.id IS NULL
LIMIT 20;
-- Задание 3 (про группировку и агрегацию): 
SELECT c.name AS "Категория", COUNT(p.id) AS "Число товаров", AVG(p.price) AS "Средняя цена" 
FROM categories c
JOIN products p ON p.category_id = c.id
GROUP BY c.name;
-- Задание 4 (про фильтрацию и сборку): 
SELECT s.store_name AS "Название магазина", SUM(oi.quantity * oi.unit_price) AS "Выручка"
FROM sellers s
JOIN products p ON p.seller_id = s.id
JOIN order_items oi ON oi.product_id = p.id
GROUP BY s.store_name
HAVING SUM(oi.quantity * oi.unit_price) > 600000;

-- Задания 5 (по запросу с подзапросом: скалярным, IN и EXISTS)
SELECT title AS "Название", price AS "Цена"
FROM products
WHERE price > (SELECT AVG(price) FROM products)
LIMIT 10;

SELECT s.store_name AS "Название магазина"
FROM sellers s
WHERE s.id IN (SELECT p.seller_id FROM products p WHERE p.price < 1200);

SELECT s.store_name
FROM sellers s
WHERE EXISTS 
(
    SELECT 1 FROM products p 
    WHERE p.seller_id = s.id AND p.price < 1020
);

-- Задание 6 (про временные таблички Common Table Expressions)
WITH seller_rev AS 
(
    SELECT s.store_name, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM sellers s
    JOIN products p ON p.seller_id = s.id
    JOIN order_items oi ON oi.product_id = p.id
    GROUP BY s.store_name
)
SELECT store_name AS "Название магазина", revenue AS "Выручка"
FROM seller_rev
WHERE revenue > 100000
ORDER BY revenue DESC;

WITH RECURSIVE category_tree AS 
(
    SELECT id, name, parent_id, 1 AS step
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    SELECT c.id, c.name, c.parent_id, ct.step + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT step, name, parent_id
FROM category_tree
ORDER BY step, name;

-- Задание 7 (про представления / заготовки)
CREATE VIEW view_category_stats AS
SELECT c.name AS category_name, COUNT(p.id) AS products_count, AVG(p.price) AS avg_price
FROM categories c
JOIN products p ON p.category_id = c.id
GROUP BY c.name;


CREATE VIEW view_seller_revenue AS
SELECT s.store_name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM sellers s
JOIN products p ON p.seller_id = s.id
JOIN order_items oi ON oi.product_id = p.id
GROUP BY s.id, s.store_name;


SELECT * FROM view_category_stats ORDER BY products_count;

SELECT * FROM view_seller_revenue ORDER BY revenue;


