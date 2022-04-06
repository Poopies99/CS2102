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
Delete from users;
Delete from refund_request;

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

INSERT INTO sells (shop_id, product_id, sell_timestamp, price, quantity) VALUES
(1, 1, '2022-04-04', 59, 10),
(2, 3, '2022-04-04', 31, 15),
(3, 3, '2022-04-04', 49, 40)
;

INSERT INTO users (id, address, name, account_closed) VALUES 
(1, 'Bishan', 'Chris', FALSE),
(2, 'Tampines', 'Ben', FALSE),
(3, 'Bedok', 'Pootis', TRUE)
;

INSERT INTO coupon_batch (id, valid_period_start, valid_period_end, reward_amount, min_order_amount) VALUES
(1, '2021-11-11', '2022-12-25', 80, 500),
(2, '2021-11-11', '2022-12-25', 80, 100)
;

INSERT INTO issued_coupon (user_id, coupon_id) VALUES 
(1, 1),
(2, 1),
(1, 2),
(2, 2)
;

INSERT INTO orders (id, user_id, coupon_id, shipping_address, payment_amount) VALUES
(1, 1, 1, 'Bishan', 1200),
(2, 2, 1, 'Bishan', 800),
(3, 2, 2, 'Bishan', 400)
;

INSERT INTO orderline (order_id, shop_id, product_id, sell_timestamp, quantity, status, delivery_date) VALUES
(1, 2, 3, '2022-04-04', 15, 'delivered', '2022-04-07'),
(2, 1, 1, '2022-04-04', 10, 'delivered', '2022-04-07'),
(3, 3, 3, '2022-04-04', 8, 'delivered', '2022-04-09')
;

INSERT INTO comment (id, user_id) VALUES
(1, 1),
(2, 2),
(3, 1),
(4, 3),
(5, 3)
;

INSERT INTO review (id, order_id, shop_id, product_id, sell_timestamp) VALUES
(1, 1, 2, 3, '2022-04-04'),
(2, 2, 1, 1, '2022-04-04')
;

INSERT INTO reply (id, other_comment_id) VALUES 
(3, 2),
(4, 2),
(5, 3) -- reply to reply
;

INSERT INTO reply_version (reply_id, reply_timestamp, content) VALUES
(3, '2022-04-06', 'What a review'),
(4, '2022-04-07', 'Interested in buying now!'),
(5, '2022-04-05', 'Geez! What a reply!')
;

INSERT INTO review_version (review_id, review_timestamp, content, rating) VALUES
(1, '2022-04-05', 'Good Product', 3),
(2, '2022-04-05', 'Excellent Product', 4) -- Trigger here
;

INSERT INTO complaint (id, status, user_id) VALUES 
(1, 'pending', 1),
(2, 'pending', 1),
(3, 'pending', 1)
;

INSERT INTO delivery_complaint (id, order_id, shop_id, product_id, sell_timestamp) VALUES
(1, 1, 2, 3, '2022-04-04')
;

INSERT INTO shop_complaint (id, shop_id) VALUES
(2, 1),
(3, 2)
;

INSERT INTO comment_complaint (id, comment_id) VALUES
(3, 1)
;

INSERT INTO employee VALUES 
(1, 'Jane', 1000),
(2, 'Jacob', 2500)
;


INSERT INTO refund_request VALUES
(1, 1, 1, 2, 3, '2022-04-04', 15, '2022-04-05', 'rejected', '2022-04-06', '2022-04-06'),
(2, 2, 2, 1, 1, '2022-04-04', 10, '2022-04-05', 'accepted', '2022-04-06', NULL),
(3, 2, 3, 3, 3, '2022-04-04', 8, '2022-04-05', 'accepted', '2022-04-07', NULL)
;

