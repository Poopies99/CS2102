Delete from complaint;
Delete from delivery_complaint;
Delete from comment;
Delete from review;
Delete from review_version;
Delete from reply;
Delete from reply_version;
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
Delete from refund_request;
Delete from users;

BEGIN TRANSACTION;
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

INSERT INTO sells (shop_id, product_id, sell_timestamp) VALUES
(1, 1, '2022-04-04 16:07:14.426782'),
(2, 2, '2022-04-04 16:07:14.426782'),
(3, 3, '2022-04-04 16:07:14.426782')
;

INSERT INTO users (id, address, name, account_closed) VALUES 
(1, 'Bishan', 'Chris', FALSE)
;

INSERT INTO coupon_batch (id, valid_period_start, valid_period_end, reward_amount, min_order_amount) VALUES
(1, '2020-11-11', '2020-12-25', 80, 1000),
(2, '2020-11-13', '2020-12-25', 80, 500),
(3, '2020-11-13', '2020-12-25', 80, 300)
;

INSERT INTO issued_coupon (user_id, coupon_id) VALUES 
(1, 1),
(1, 2),
(1, 3)
;

INSERT INTO orders (id, user_id, coupon_id) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 1, 3)
;

INSERT INTO orderline (order_id, shop_id, product_id, sell_timestamp, quantity) VALUES
(2, 1, 1, '2022-04-04 16:07:14.426782', 10),
(2, 2, 2, '2022-04-04 16:07:14.426782', 10),
(3, 3, 3, '2022-04-04 16:07:14.426782', 10)
;
COMMIT;