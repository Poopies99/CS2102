Delete from sells;
Delete from shop;
Delete from product;
Delete from category;
Delete from manufacturer;
Delete from issued_coupon;
Delete from coupon_batch;
Delete from users;
Delete from orders;

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

INSERT INTO coupon_batch (id, valid_period_start, valid_period_end, reward_amount, min_order_amount) VALUES
(1, '2020-11-11', '2020-12-25', 80, 1000)
;

INSERT INTO issued_coupon (user_id, coupon_id) VALUES 
(1, 1)
;

-- Test case
-- insert into orders (id, user_id, coupon_id, shipping_address, payment_amount) values (1, 1, 1, 'Bishan', 500);

