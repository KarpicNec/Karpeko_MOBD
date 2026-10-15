-- Лабораторная работа №2. Наполнение тестовыми данными
-- Пользователи: 1000
INSERT INTO users (full_name, email, phone)
SELECT
    'Пользователь №' || g,
    'user' || g || '@mail.ru',
    '+7' || (random() * 9000000000 + 1000000000)::bigint
FROM generate_series(1, 1000) AS g;

-- Адреса: 1000
INSERT INTO addresses (user_id, city, street, house, apartment)
SELECT
    (random() * 999 + 1)::int,
    'Город №' || (random() * 49 + 1)::int,
    'Улица №' || (random() * 49 + 1)::int,
    (random() * 99 + 1)::int::text,
    (random() * 499 + 1)::int::text
FROM generate_series(1, 1000) AS g;

-- Продавцы: 100
INSERT INTO sellers (user_id, store_name, description)
SELECT
    g,
    'Магазин №' || g,
    'Описание №' || g
FROM generate_series(1, 100) AS g;

-- Категории
INSERT INTO categories (name) VALUES
    ('Электроника'), ('Книги'), ('Одежда'), ('Сад и огород'), ('Спорт'),
    ('Обувь'), ('Детские товары'), ('Косметика'), ('Парфюмерия'), ('Канцтовары'),
    ('Зоотовары'), ('Ремонт и строительство'), ('Лекарства'), ('Техника'), ('Продукты питания');

-- Товары: 2000
INSERT INTO products (seller_id, category_id, title, description, price, is_active)
SELECT
    (random() * 99 + 1)::int,
    (random() * 14 + 1)::int,
    'Товар №' || g,
    'Описание товара №' || g,
    (random() * 9000 + 1000)::numeric(12,2),
    TRUE
FROM generate_series(1, 2000) AS g;

-- Остатки: на каждый товар
INSERT INTO stock (product_id, quantity)
SELECT id, (random() * 300)::int
FROM products;

-- Корзины: 1000
INSERT INTO carts (user_id)
SELECT (random() * 999 + 1)::int
FROM generate_series(1, 1000) AS g;

-- Позиции корзины: 2000
INSERT INTO cart_items (cart_id, product_id, quantity)
SELECT
    (random() * 999 + 1)::int,
    (random() * 1999 + 1)::int,
    (random() * 4 + 1)::int
FROM generate_series(1, 2000) AS g
ON CONFLICT DO NOTHING;

-- Заказы: 1500
INSERT INTO orders (user_id, status, total_amount, created_at)
SELECT
    (random() * 999 + 1)::int,
    'created',
    0,
    now() - (random() * interval '365 days')
FROM generate_series(1, 1500) AS g;

-- Каждому заказу закинута одна позиция (гарантированно 1500 строк, чтобы не было пустых заказов)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    o.id,
    (random() * 1999 + 1)::int,
    (random() * 3 + 1)::int,
    (random() * 9000 + 1000)::numeric(12,2)
FROM orders o;

-- + случайные позиции в заказы
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT
    (random() * 1499 + 1)::int,
    (random() * 1999 + 1)::int,
    (random() * 3 + 1)::int,
    (random() * 9000 + 1000)::numeric(12,2)
FROM generate_series(1, 1500) AS g
ON CONFLICT DO NOTHING;

-- Пересчёт суммы в заказах
UPDATE orders
SET total_amount = COALESCE((
    SELECT SUM(quantity * unit_price)
    FROM order_items
    WHERE order_items.order_id = orders.id
), 0);

-- Платежи: 1500 на каждый заказ
INSERT INTO payments (order_id, amount, status, paid_at)
SELECT
    id,
    total_amount,
    'succeeded',
    created_at + interval '1 hour'
FROM orders
WHERE total_amount > 0;

-- Доставки: 1500 на каждый заказ
INSERT INTO deliveries (order_id, address_id, delivery_status, delivery_date)
SELECT
    id,
    (random() * 999 + 1)::int,
    'delivered',
    created_at + interval '5 days'
FROM orders;

-- Отзывы: 2000
INSERT INTO reviews (product_id, user_id, score, comment, created_at)
SELECT
    (random() * 1999 + 1)::int,
    (random() * 999 + 1)::int,
    (random() * 4 + 1)::int,
    'Отзыв №' || g,
    now() - (random() * interval '365 days')
FROM generate_series(1, 2000) AS g
ON CONFLICT DO NOTHING;