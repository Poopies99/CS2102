CREATE OR REPLACE PROCEDURE place_order(user_id INTEGER, coupon_id INTEGER, shipping_address TEXT, shop_ids INTEGER[], product_ids INTEGER[], sell_timestamps TIMESTAMP[], quantities INTEGER[], shipping_costs NUMERIC[])
AS $$
BEGIN
	FOR i IN array_lower(product_ids, 1)..array_upper(product_ids,1)
	LOOP
		WITH price AS (SELECT price FROM sells WHERE shop_id = shop_ids[i] AND product_id = product_ids[i]),
			 order_id AS (INSERT INTO orders(user_id, coupon_id, shipping_address, payment_amount) SELECT user_id, coupon_id, shipping_address, (price.price * quantities[i]) + shipping_costs[i] FROM price RETURNING id)
		INSERT INTO orderline(order_id, shop_id, product_id, sell_timestamp, quantity, shipping_cost, status) SELECT order_id.id, shop_ids[i], product_ids[i], sell_timestamps[i], quantities[i], shipping_costs[i], 'being_processed' FROM order_id;
	END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE PROCEDURE review(user_id INTEGER, order_id INTEGER, shop_id INTEGER, product_id INTEGER, sell_timestamp TIMESTAMP, content TEXT, rating INTEGER, comment_timestamp TIMESTAMP)
AS $$
WITH comment_id AS (INSERT INTO comment(user_id) values(user_id) RETURNING id),
	 review_id AS (INSERT INTO review(id, order_id, shop_id, product_id, sell_timestamp) SELECT comment_id.id, order_id, shop_id, product_id, sell_timestamp FROM comment_id RETURNING id)
INSERT INTO review_version (review_id, review_timestamp, content, rating) SELECT review_id.id, comment_timestamp, content, rating FROM review_id;
$$ LANGUAGE sql;


CREATE PROCEDURE reply(user_id INTEGER, other_comment_id INTEGER, content TEXT, reply_timestamp TIMESTAMP)
AS $$
WITH comment_id AS (INSERT INTO comment(user_id) values(user_id) RETURNING id),
	 reply_id AS (INSERT INTO reply(id, other_comment_id) SELECT comment_id.id, other_comment_id FROM comment_id RETURNING id)
INSERT INTO reply_version(reply_id, reply_timestamp, content) SELECT reply_id.id, reply_timestamp, content FROM reply_id;
$$ LANGUAGE sql;

CALL place_order(1, 1, 'test', '{1,2}', '{1,2}', '{"2022-03-04 16:05:15.723336+07","2022-03-04 16:05:15.723336+07"}', '{50, 100}', '{1,2}');
CALL review(1, 1, 1, 1, '2022-03-04 16:05:15.723336+07', 'test', 5, '2022-03-04 16:05:15.723336+07');
CALL reply(2, 1, 'WOW', '2022-03-04 17:05:15.723336+07');