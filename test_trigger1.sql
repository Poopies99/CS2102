Delete from refund_request;
Delete from orderline;
Delete from sells;
Delete from shop;
Delete from product;
Delete from category;
Delete from manufacturer;
Delete from orders;
Delete from issued_coupon;
Delete from coupon_batch;
Delete from users;
Delete from refund_request;

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
(1, 1, current_timestamp, 59, 10)
;

-- Test case
-- insert into product (id, name, description, category, manufacturer) VALUES (4, 'Another White Tee', 'Yet Another white tee', 3, 1);
