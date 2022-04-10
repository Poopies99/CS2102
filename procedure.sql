drop procedure if exists reply;
drop procedure if exists place_order;
drop procedure if exists review;

drop procedure if exists reply;
drop procedure if exists place_order;
drop procedure if exists review;

CREATE OR REPLACE PROCEDURE place_order(input_user_id INTEGER, input_coupon_id INTEGER, input_shipping_address TEXT, input_shop_ids INTEGER[], input_product_ids INTEGER[], input_sell_timestamps TIMESTAMP[], input_quantities INTEGER[], input_shipping_costs NUMERIC[])
AS $$
DECLARE
orderID integer;
	currentPrice integer:=0;
	totalSum integer:=0;
	couponDiscount integer:=0;
BEGIN
FOR i IN array_lower(input_product_ids, 1)..array_upper(input_product_ids,1)
	LOOP
SELECT price into currentPrice FROM sells WHERE shop_id = input_shop_ids[i] AND product_id = input_product_ids[i];
totalSum:=totalSum + (currentPrice*input_quantities[i])+ input_shipping_costs[i];
END LOOP;
INSERT INTO orders(id, user_id, coupon_id, shipping_address, payment_amount) VALUES((SELECT MAX(id) FROM orders)+1, input_user_id, input_coupon_id, input_shipping_address, totalSum) RETURNING id INTO orderID;
FOR i IN array_lower(input_product_ids, 1)..array_upper(input_product_ids,1)
	LOOP
		INSERT INTO orderline(order_id, shop_id, product_id, sell_timestamp, quantity, shipping_cost, status) VALUES(orderID, input_shop_ids[i], input_product_ids[i], input_sell_timestamps[i], input_quantities[i], input_shipping_costs[i], 'being_processed');
UPDATE sells SET quantity = quantity - input_quantities[i] WHERE shop_id = input_shop_ids[i] AND product_id = input_product_ids[i];
END LOOP;
	IF EXISTS (SELECT reward_amount FROM coupon_batch WHERE id = input_coupon_id) THEN
SELECT reward_amount into couponDiscount FROM coupon_batch WHERE id = input_coupon_id;
UPDATE orders SET payment_amount = payment_amount - couponDiscount WHERE id = orderID;
END IF;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE review(input_user_id INTEGER, input_order_id INTEGER, input_shop_id INTEGER, input_product_id INTEGER, input_sell_timestamp TIMESTAMP, input_content TEXT, input_rating INTEGER, input_comment_timestamp TIMESTAMP)
AS $$
SELECT setval('comment_id_seq', COALESCE((SELECT MAX(id)+1 FROM comment), 1), false);
WITH comment_id AS (INSERT INTO comment(user_id) VALUES(input_user_id) RETURNING id),
    review_id AS (INSERT INTO review(id, order_id, shop_id, product_id, sell_timestamp) SELECT comment_id.id, input_order_id, input_shop_id, input_product_id, input_sell_timestamp FROM comment_id RETURNING id)
INSERT INTO review_version (review_id, review_timestamp, content, rating) SELECT review_id.id, input_comment_timestamp, input_content, input_rating FROM review_id;
$$ LANGUAGE sql;


CREATE OR REPLACE PROCEDURE reply(input_user_id INTEGER, input_other_comment_id INTEGER, input_content TEXT, input_reply_timestamp TIMESTAMP)
AS $$
SELECT setval('comment_id_seq', COALESCE((SELECT MAX(id)+1 FROM comment), 1), false);
WITH comment_id AS (INSERT INTO comment(user_id) values(input_user_id) RETURNING id),
    reply_id AS (INSERT INTO reply(id, other_comment_id) SELECT comment_id.id, input_other_comment_id FROM comment_id RETURNING id)
INSERT INTO reply_version(reply_id, reply_timestamp, content) SELECT reply_id.id, input_reply_timestamp, input_content FROM reply_id;
$$ LANGUAGE sql;


INSERT INTO issued_coupon(user_id, coupon_id) VALUES(3,2);
--CALL place_order(3, 2, 'Bishan', '{1}', '{1}', '{"2022-04-04 16:07:14.426782"}', '{1}', '{1}');
CALL place_order(3, 2, 'Bishan', '{1,2}', '{1,3}', '{"2022-04-04 16:07:14.426782", "2022-04-04 16:07:14.426782"}', '{3, 3}', '{1,2}');
CALL place_order(3, null, 'Bishan', '{1,2}', '{1,3}', '{"2022-04-04 16:07:14.426782", "2022-04-04 16:07:14.426782"}', '{3, 3}', '{1,2}');
CALL review(3, 4, 1, 1,'2022-04-04 16:07:14.426782','test',5,'2022-04-04 16:07:14.426782');
CALL reply(3, 5, 'WOW', '2022-04-04 16:07:14.426782');
