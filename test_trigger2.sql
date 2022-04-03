Delete from sells;
Delete from orders;
Delete from shop;
Delete from product;
Delete from category;
Delete from manufacturer;
Delete from issued_coupon;
Delete from users;

INSERT INTO shop(id, name) VALUES 
(1, 'Nike'),
(2, 'Timberlands'),
(3, 'Adidas')
;

INSERT INTO category (id, name, parent) VALUES
(1, 'Wearables', 1),
(2, 'Shoes', 1),
(3, 'Shirts', 1),
(4, 'Pants', 1)
;

INSERT INTO manufacturer (id, name, country) VALUES
(1, 'ChinaProduce', 'China')
;

INSERT INTO product (id, name, description, category, manufacturer) VALUES
(1, 'Hype-Beast Shoes', 'Shoes that give you that F-Boi look', 2, 1),
(2, 'White-tee', 'Plain White-Tee', 3, 1),
(3, 'Black Jeans', 'Dark Jeans', 4, 1)
;

INSERT INTO sells (shop_id, product_id, sell_timestamp, price, quantity) VALUES
(1, 1, current_timestamp, 59, 10),
(2, 2, current_timestamp, 31, 15),
(3, 3, current_timestamp, 49, 8)
;

INSERT INTO users (id, address, name, account_closed) VALUES 
(1, 'Bishan', 'Chris', FALSE)
;

-- Test case
-- insert into orders (id, user_id, payment_amount) VALUES (1, 1, 279);

-- is this a constraint on orderline or order? It does not make sense for it to be put at orders because it order to create orderline, you need to first insert orderline values in which it will trigger the trigger.