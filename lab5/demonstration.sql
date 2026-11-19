-- Успешная транзакция (про BEGIN и COMMIT)
SELECT product_id, quantity AS stock_before FROM stock WHERE product_id = 1;

BEGIN;
INSERT INTO orders (user_id, status, total_amount)
VALUES (1, 'created', 0)
RETURNING id;                -- запомнить полученный id как 1509, при повторе будет на 1 больше..

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1509, 1, 2, (SELECT price FROM products WHERE id = 1));

UPDATE stock SET quantity = quantity - 2, updated_at = now() WHERE product_id = 1;

UPDATE orders SET total_amount = (
    SELECT SUM(quantity * unit_price) FROM order_items WHERE order_id = 1509
) WHERE id = 1509;

COMMIT;

SELECT product_id, quantity AS stock_after FROM stock WHERE product_id = 1;
SELECT * FROM orders WHERE id = 1509;
SELECT * FROM order_items WHERE order_id = 1509;


-- Транзакция с ошибкой и ROLLBACK
SELECT COUNT(*) AS orders_before FROM orders;
BEGIN;

INSERT INTO orders (user_id, status, total_amount)
VALUES (1, 'created', 0)
RETURNING id;                 -- вернул 1510

INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (1510, 999999, 1, 100.00);     -- alert!! здесь ОШИБКА (ведь товара 999999 нет)

ROLLBACK;

SELECT COUNT(*) AS orders_after FROM orders;
SELECT * FROM orders WHERE id = 1510; -- пусто ну то есть откат сработал


-- place_order успешный вызов
SELECT quantity FROM stock WHERE product_id = 1;
-- вернуло сток = 92
SELECT place_order(1, '[{"product_id": 1, "quantity": 2}, {"product_id": 2, "quantity": 1}]'::jsonb);
-- вернёт id заказа 1512

SELECT * FROM orders WHERE id = 1512;
SELECT * FROM order_items WHERE order_id = 1512;
SELECT quantity FROM stock WHERE product_id IN (1, 2);


-- place_order и нехватка товара (атомарность)
SELECT COUNT(*) AS orders_before FROM orders; -- там 1510

SELECT place_order(1, '[{"product_id": 1, "quantity": 1000000}]'::jsonb);
-- столько товара на складе нет

SELECT COUNT(*) AS orders_after FROM orders;   -- число не изменилось, все еще 1510
SELECT quantity FROM stock WHERE product_id = 1;  -- остаток не изменился


-- seller_revenue + сверка вручную
SELECT seller_revenue(1, '2025-01-01', '2025-12-31');

SELECT SUM(oi.quantity * oi.unit_price)
FROM sellers s
JOIN products p ON p.seller_id = s.id
JOIN order_items oi ON oi.product_id = p.id
JOIN orders o ON o.id = oi.order_id
WHERE s.id = 1 AND o.created_at::date BETWEEN '2025-01-01' AND '2025-12-31';


-- Триггер аудита цены
SELECT id, price FROM products WHERE id = 1;

UPDATE products SET price = price + 100 WHERE id = 1;

SELECT * FROM product_price_audit WHERE product_id = 1 ORDER BY changed_at DESC;

-- повторный UPDATE с тем же значением не будет записан в журнал
UPDATE products SET price = price WHERE id = 1;
SELECT COUNT(*) FROM product_price_audit WHERE product_id = 1; -- возвращает 1


-- Триггер рейтинга
SELECT id, title, rating FROM products WHERE id = 1;  -- 1	"Товар №1"	2.00

INSERT INTO reviews (product_id, user_id, score, comment)
VALUES (1, 2, 5, 'Тестовый отзыв чисто для триггера');

SELECT id, title, rating FROM products WHERE id = 1;  -- 1	"Товар №1"	3.50

DELETE FROM reviews
WHERE product_id = 1 AND user_id = 2 AND comment = 'Тестовый отзыв чисто для триггера';

SELECT id, title, rating FROM products WHERE id = 1; -- Снова 1	"Товар №1"	2.00






