-- Лабораторная работа №1. гига много таблиц для маркетплейса
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS carts CASCADE;
DROP TABLE IF EXISTS stock CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS addresses CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Пользователи
CREATE TABLE users (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	full_name VARCHAR(255) NOT NULL,
	email VARCHAR(255) NOT NULL UNIQUE,
	phone VARCHAR(255) UNIQUE,
	created_at TIMESTAMP NOT NULL DEFAULT now(),
	CONSTRAINT email_format CHECK (
		email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
	)
);

-- 2. Адреса
CREATE TABLE addresses (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
	city VARCHAR(255) NOT NULL,
	street VARCHAR(255) NOT NULL,
	house VARCHAR(255) NOT NULL,
	apartment VARCHAR(255) NOT NULL
);

-- 3. Продавцы
CREATE TABLE sellers (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	store_name VARCHAR(255) NOT NULL UNIQUE,
	description TEXT,
	created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 4. Категории
CREATE TABLE categories (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	parent_id INTEGER REFERENCES categories(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	name VARCHAR(255) NOT NULL UNIQUE,
	CONSTRAINT categories_is_not_self_parent CHECK (
		parent_id IS NULL OR parent_id <> id
	)
);

-- 5. Товары
CREATE TABLE products (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	seller_id INTEGER NOT NULL REFERENCES sellers(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	title VARCHAR(255) NOT NULL,
	description TEXT,
	price DECIMAL(12,2) NOT NULL CHECK (price > 0),
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 6. СТОК
CREATE TABLE stock (
	product_id INTEGER PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
	quantity INTEGER NOT NULL DEFAULT 0 CHECK (quantity >= 0),
	updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 7. Корзины
CREATE TABLE carts (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
	created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 8. Позиции в корзине
CREATE TABLE cart_items (
	cart_id INTEGER NOT NULL REFERENCES carts(id) ON DELETE CASCADE ON UPDATE CASCADE,
	product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	quantity INTEGER NOT NULL CHECK (quantity > 0),
	PRIMARY KEY (cart_id, product_id)
);

-- 9. Заказы
CREATE TABLE orders (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	status VARCHAR(255) NOT NULL DEFAULT 'created', -- можно если надо тут поставить CHECK (status IN ('created', 'paid', 'shipped', 'delivered', 'cancelled'))
	total_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total_amount >= 0),
	created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- 10. Позиции в заказе
CREATE TABLE order_items (
	order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
	product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	quantity INTEGER NOT NULL CHECK (quantity > 0),
	unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
	PRIMARY KEY (order_id, product_id)
);

-- 11. Платежи
CREATE TABLE payments (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
	amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
	status VARCHAR(255) NOT NULL DEFAULT 'pending', -- можно и с заказами CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded'))
	paid_at TIMESTAMP
);

-- 12. Доставки
CREATE TABLE deliveries (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	order_id INTEGER NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE ON UPDATE CASCADE,
	address_id INTEGER NOT NULL REFERENCES addresses(id) ON DELETE RESTRICT ON UPDATE CASCADE,
	delivery_status VARCHAR(255) NOT NULL DEFAULT 'pending', -- можно и с заказами и с платежами CHECK (delivery_status IN ('pending', 'packed', 'shipped', 'delivered', 'cancelled'))
	delivery_date TIMESTAMP
);

-- 13. Отзывы
CREATE TABLE reviews (
	id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
	user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
	score INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
	comment TEXT,
	created_at TIMESTAMP NOT NULL DEFAULT now(),
	CONSTRAINT review_one_for_user_product UNIQUE (product_id, user_id)
);

-- Индексы по внешним ключам
CREATE INDEX idx_addresses_user_id ON addresses(user_id);
CREATE INDEX idx_sellers_user ON sellers(user_id);
CREATE INDEX idx_products_seller ON products(seller_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_carts_user ON carts(user_id);
CREATE INDEX idx_cart_items_product ON cart_items(product_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_deliveries_address ON deliveries(address_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);