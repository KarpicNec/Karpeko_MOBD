-- Задание 2 (про DISTINCT): 
SELECT DISTINCT status AS "Статус", (total_amount > 5000) AS "Сумма свыше 5000"
FROM orders
ORDER BY "Статус", "Сумма свыше 5000";

-- Задание 3 (про AND и OR): 
SELECT id, product_id, user_id, score, comment
FROM reviews
WHERE (score = 5 OR score = 1) AND created_at > (now() - interval '30 days')
LIMIT 25;

-- Задание 4.1 (про BETWEEN): 
SELECT id, user_id, status, total_amount, created_at
FROM orders
WHERE total_amount BETWEEN 15000 AND 20000
ORDER BY created_at DESC
LIMIT 20;

-- Задание 4.2 (про IN): 
SELECT id, product_id, user_id, score, comment
FROM reviews
WHERE score IN (1, 2, 3)
LIMIT 30;

-- Задание 4.3 (про LIKE): 
SELECT id, full_name, email
FROM users
WHERE email ILIKE 'user2%@%'
ORDER BY id
LIMIT 30;

-- Задание 4.4 (про IS NULL): 
SELECT id, full_name, email, phone
FROM users
WHERE phone IS NULL
ORDER BY id
LIMIT 10;

-- Задание 5 (про сортировку): 
SELECT id, seller_id, title, price
FROM products
ORDER BY seller_id ASC, price DESC
LIMIT 30;

-- Задание 6 (про LIMIT и OFFSET): 
-- стр1
SELECT id, title, price, seller_id
FROM products
ORDER BY id
LIMIT 20 OFFSET 0;
-- стр2
SELECT id, title, price, seller_id
FROM products
ORDER BY id
LIMIT 20 OFFSET 20;







-- SELECT * FROM orders











