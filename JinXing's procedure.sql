CREATE OR REPLACE PROCEDURE place_order(user_id INTEGER, coupon_id INTEGER, shipping_address TEXT, shop_ids INTEGER[], product_ids INTEGER[], sell_timestamps TIMESTAMP[], quantities INTEGER[], shipping_costs NUMERIC[])
AS $$
BEGIN
	FOR i IN array_lower(product_ids, 1)..array_upper(product_ids,1)
	LOOP
		WITH price AS (SELECT price FROM sells WHERE shop_id = shop_ids[i] AND product_id = product_ids[i]),
			 order_id AS (INSERT INTO orders(id, user_id, coupon_id, shipping_address, payment_amount) SELECT (SELECT MAX(id) FROM orders)+1, user_id, coupon_id, shipping_address, (price.price * quantities[i]) + shipping_costs[i] FROM price RETURNING id)
		INSERT INTO orderline(order_id, shop_id, product_id, sell_timestamp, quantity, shipping_cost, status) SELECT order_id.id, shop_ids[i], product_ids[i], sell_timestamps[i], quantities[i], shipping_costs[i], 'being_processed' FROM order_id;
		UPDATE sells SET quantity = quantity - quantities[i] WHERE shop_id = shop_ids[i] AND product_id = product_ids[i];
	END LOOP;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE review(user_id INTEGER, order_id INTEGER, shop_id INTEGER, product_id INTEGER, sell_timestamp TIMESTAMP, content TEXT, rating INTEGER, comment_timestamp TIMESTAMP)
AS $$
SELECT setval('comment_id_seq', COALESCE((SELECT MAX(id)+1 FROM comment), 1), false);
WITH comment_id AS (INSERT INTO comment(user_id) VALUES(user_id) RETURNING id),
	 review_id AS (INSERT INTO review(id, order_id, shop_id, product_id, sell_timestamp) SELECT comment_id.id, order_id, shop_id, product_id, sell_timestamp FROM comment_id RETURNING id)
INSERT INTO review_version (review_id, review_timestamp, content, rating) SELECT review_id.id, comment_timestamp, content, rating FROM review_id;
$$ LANGUAGE sql;


CREATE OR REPLACE PROCEDURE reply(user_id INTEGER, other_comment_id INTEGER, content TEXT, reply_timestamp TIMESTAMP)
AS $$
SELECT setval('comment_id_seq', COALESCE((SELECT MAX(id)+1 FROM comment), 1), false);
WITH comment_id AS (INSERT INTO comment(user_id) values(user_id) RETURNING id),
	 reply_id AS (INSERT INTO reply(id, other_comment_id) SELECT comment_id.id, other_comment_id FROM comment_id RETURNING id)
INSERT INTO reply_version(reply_id, reply_timestamp, content) SELECT reply_id.id, reply_timestamp, content FROM reply_id;
$$ LANGUAGE sql;

CALL place_order(3, null, 'Bishan', '{1,2}', '{1,3}', '{"2022-04-04 16:07:14.426782", "2022-04-04 16:07:14.426782"}', '{1, 1}', '{1,2}');
CALL review(3, 4, 1, 1,'2022-04-04 16:07:14.426782','test',5,'2022-04-04 16:07:14.426782');
CALL reply(3, 5, 'WOW', '2022-04-04 16:07:14.426782');
