-- Задание 1 (про рейтинг разными подходами): 
SELECT c.name AS "Категория", p.title AS "Товар", p.price AS "Цена",
	ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY p.price DESC) AS "row_number",
	RANK() OVER (PARTITION BY c.id ORDER BY p.price DESC) AS "rank",
	DENSE_RANK() OVER (PARTITION BY c.id ORDER BY p.price DESC) AS "dense_rank"
FROM products p
JOIN categories c ON c.id = p.category_id
ORDER BY c.id, p.price DESC

-- Задание 2 (про 3 самых дорогих в категориях): 
WITH RankedProducts AS 
(
	SELECT c.name AS category_name, p.title, p.price,
		ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY p.price DESC) AS rn
	FROM products p
	JOIN categories c ON c.id = p.category_id
)
SELECT * 
FROM RankedProducts
WHERE rn <= 3
ORDER BY category_name, rn;

-- Задание 3 (про нарастающий итог выручки): 
WITH DailyRevenue AS 
(
	SELECT o.created_at::date AS day, SUM(oi.quantity * oi.unit_price) AS day_revenue
	FROM orders o
	JOIN order_items oi ON oi.order_id = o.id
	GROUP BY day
)
SELECT day AS "Дата", ROUND(day_revenue, 2) AS "Выручка за день", ROUND(SUM(day_revenue) OVER (ORDER BY day), 2) AS "Нарастающий итог"
FROM DailyRevenue
ORDER BY day;

-- Задание 4 (про долю продавца в категории):
WITH SellerRevenue AS 
(
	SELECT c.name AS category_name, s.store_name, SUM(oi.quantity * oi.unit_price) AS revenue
	FROM sellers s
	JOIN products p ON p.seller_id = s.id
	JOIN categories c ON c.id = p.category_id
	JOIN order_items oi ON oi.product_id = p.id
	GROUP BY c.name, s.store_name
)
SELECT category_name AS "Категория", store_name AS "Магазин",
	ROUND(revenue, 2) AS "Выручка",
	ROUND(SUM(revenue) OVER (PARTITION BY category_name), 2) AS "Выручка категории",
	ROUND(revenue / SUM(revenue) OVER (PARTITION BY category_name) * 100, 2) AS "Доля, %"
FROM SellerRevenue
ORDER BY category_name, revenue DESC

-- Задание 5 (про LAG и LEAD для выручки): 
WITH DailyRevenue AS 
(
	SELECT o.created_at::date AS day, SUM(oi.quantity * oi.unit_price) AS day_revenue
	FROM orders o
	JOIN order_items oi ON oi.order_id = o.id
	GROUP BY o.created_at::date
)
SELECT day AS "Дата", ROUND(day_revenue, 2) AS "Выручка",
	ROUND(LAG(day_revenue) OVER (ORDER BY day), 2) AS "Выручка вчера",
	ROUND(day_revenue - LAG(day_revenue) OVER (ORDER BY day), 2) AS "Прирост со вчера",
	ROUND(LEAD(day_revenue) OVER (ORDER BY day), 2) AS "Выручка завтра"
FROM DailyRevenue
ORDER BY day
LIMIT 20;

-- Задание 6 (про сравнение оконной функции и группировки): 
SELECT title AS "Товар", price AS "Цена", category_id AS "Категория ID",
	ROUND(AVG(price) OVER (PARTITION BY category_id), 2) AS "Средняя цена категории"
FROM products
-----------
SELECT p.title AS "Товар", p.price AS "Цена", p.category_id AS "Категория ID", 
	ROUND(cat_avg.avg_price, 2) AS "Средняя цена категории"
FROM products p
JOIN 
(
    SELECT category_id, AVG(price) AS avg_price
    FROM products
    GROUP BY category_id
) 
cat_avg ON cat_avg.category_id = p.category_id
ORDER BY p.category_id, p.id













