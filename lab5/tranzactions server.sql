-- Лабораторная работа №5. Транзакции, целостность данных и серверная логика
-- 0. Очистка новых объектов конкретно этой лабы 
DROP TRIGGER IF EXISTS trg_price_audit ON products;
DROP TRIGGER IF EXISTS trg_update_rating ON reviews;
DROP FUNCTION IF EXISTS log_price_change();
DROP FUNCTION IF EXISTS update_product_rating();
DROP FUNCTION IF EXISTS place_order(INTEGER, JSONB);
DROP FUNCTION IF EXISTS seller_revenue(INTEGER, DATE, DATE);
DROP TABLE IF EXISTS product_price_audit;

-- Журнал аудита изменения цен
CREATE TABLE product_price_audit 
(
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INTEGER NOT NULL,
    old_price DECIMAL(12,2) NOT NULL,
    new_price DECIMAL(12,2) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_price_audit_product ON product_price_audit(product_id);

-- Денормализованное поле среднего рейтинга
ALTER TABLE products ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2) NOT NULL DEFAULT 0;

-- Триггер аудита цены
CREATE OR REPLACE FUNCTION log_price_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.price IS DISTINCT FROM NEW.price THEN
        INSERT INTO product_price_audit (product_id, old_price, new_price)
        VALUES (OLD.id, OLD.price, NEW.price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_price_audit
AFTER UPDATE OF price ON products
FOR EACH ROW
EXECUTE FUNCTION log_price_change();

-- Триггер поддержки среднего рейтинга товара
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_product_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_product_id := OLD.product_id;
    ELSE
        v_product_id := NEW.product_id;
    END IF;

    UPDATE products
    SET rating = COALESCE(
        (SELECT AVG(score) FROM reviews WHERE product_id = v_product_id),
        0
    )
    WHERE id = v_product_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_rating
AFTER INSERT OR UPDATE OR DELETE ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_product_rating();

-- Первичное заполнение рейтинга для уже существующих товаров
UPDATE products p
SET rating = COALESCE(
    (SELECT AVG(score) FROM reviews WHERE product_id = p.id),
    0
);

-- Функция атомарного оформления заказа
CREATE OR REPLACE FUNCTION place_order(
    p_user_id INTEGER,
    p_items JSONB
) RETURNS INTEGER AS $$
DECLARE
    v_order_id INTEGER;
    v_item RECORD;
    v_price DECIMAL(12,2);
    v_stock_qty INTEGER;
BEGIN
    INSERT INTO orders (user_id, status, total_amount)
    VALUES (p_user_id, 'created', 0)
    RETURNING id INTO v_order_id;

    FOR v_item IN
        SELECT * FROM jsonb_to_recordset(p_items)
            AS x(product_id INTEGER, quantity INTEGER)
    LOOP
        SELECT quantity INTO v_stock_qty
        FROM stock
        WHERE product_id = v_item.product_id;

        IF v_stock_qty IS NULL OR v_stock_qty < v_item.quantity THEN
            RAISE EXCEPTION 'Недостаточно товара на складе (product_id=%, запрошено=%, доступно=%)',
                v_item.product_id, v_item.quantity, COALESCE(v_stock_qty, 0);
        END IF;

        SELECT price INTO v_price
        FROM products
        WHERE id = v_item.product_id;

        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_item.product_id, v_item.quantity, v_price);

        UPDATE stock
        SET quantity = quantity - v_item.quantity,
            updated_at = now()
        WHERE product_id = v_item.product_id;
    END LOOP;

    UPDATE orders
    SET total_amount = (
        SELECT SUM(quantity * unit_price)
        FROM order_items
        WHERE order_id = v_order_id
    )
    WHERE id = v_order_id;

    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- Функция выручки продавца за период
CREATE OR REPLACE FUNCTION seller_revenue(
    p_seller_id INTEGER,
    p_start DATE,
    p_end DATE
) RETURNS DECIMAL(14,2) AS $$
DECLARE
    v_revenue DECIMAL(14,2);
BEGIN
    SELECT COALESCE(SUM(oi.quantity * oi.unit_price), 0)
    INTO v_revenue
    FROM sellers s
    JOIN products p ON p.seller_id = s.id
    JOIN order_items oi ON oi.product_id = p.id
    JOIN orders o ON o.id = oi.order_id
    WHERE s.id = p_seller_id
      AND o.created_at::date BETWEEN p_start AND p_end;

    RETURN v_revenue;
END;
$$ LANGUAGE plpgsql;



