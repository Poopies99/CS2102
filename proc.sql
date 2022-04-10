--Triggers
drop trigger if exists shop_constraint on sells;
drop trigger if exists order_constraint on orderline;
drop trigger if exists coupon_constraint on orders;
drop trigger if exists refund_constraint1 on refund_request;
drop trigger if exists refund_constraint2 on refund_request;
drop trigger if exists refund_constraint3 on refund_request;
drop trigger if exists comment_constraint1 on review;
drop trigger if exists comment_constraint2 on reply;
drop trigger if exists comment_constraint3 on review;
drop trigger if exists comment_constraint4 on reply;
drop trigger if exists comment_constraint5 on review;
drop trigger if exists complaint_constraint1 on delivery_complaint;
drop trigger if exists complaint_constraint2 on delivery_complaint;
drop trigger if exists complaint_constraint3 on comment_complaint;
drop trigger if exists complaint_constraint4 on shop_complaint;
--Procedures
drop procedure if exists reply;
drop procedure if exists place_order;
drop procedure if exists review;
--Functions
drop function if exists view_comments;
drop function if exists get_most_returned_products_from_manufacturer;
drop function if exists get_worst_shops;

---Triggers Main Code
create or replace function trigger1()
returns trigger as $$
declare count_unique integer;
 		count_shop integer;
begin
select count(distinct shop.id) INTO count_unique from shop, sells where shop.id = sells.shop_id;
select count(distinct shop.id) INTO count_shop from shop;
if count_shop > count_unique then
		raise notice 'Contraint Violated, Each shop needs to sell at least one product.';
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger shop_constraint after insert on sells deferrable initially immediate for each row execute function trigger1();

create or replace function trigger2()
returns trigger as $$
declare count_unique integer;
		count_order integer;
begin
select count(distinct orderline.order_id) INTO count_unique from orderline;
select count(distinct orders.id) INTO count_order from orders;
if count_order > count_unique then
		raise exception 'Constraint Violated, Each order needs to include one or more product';
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger order_constraint after insert on orderline deferrable initially immediate for each row execute function trigger2();

create or replace function trigger3()
returns trigger as $$
declare min_amt numeric;
begin
select min_order_amount INTO min_amt from coupon_batch where coupon_batch.id = NEW.coupon_id;
if min_amt >= NEW.payment_amount then
		raise exception 'Constraint Violated, Minimum coupon amount exceeds total payment amount';
return null;
end if;
return NEW;
end;
$$ language plpgsql;

create trigger coupon_constraint before insert on orders for each row execute function trigger3();

create or replace function trigger4()
returns trigger as $$
declare refund_qty integer;
		order_qty integer;
begin
select sum(quantity) INTO refund_qty from refund_request where order_id = NEW.order_id;
select sum(quantity) INTO order_qty from orderline where NEW.order_id = order_id and NEW.shop_id = shop_id and NEW.product_id = product_id;
if order_qty < refund_qty then
		raise exception 'Constraint Violated, Sum of quantity of refunds exceeds order quantity';
return null;
end if;
return NEW;
end;
$$ language plpgsql;

create constraint trigger refund_constraint1 after insert on refund_request for each row execute function trigger4();

create or replace function trigger5()
returns trigger as $$
declare deli_date date;
		date_diff integer;
begin
select orderline.delivery_date INTO deli_date from orderline where orderline.order_id = NEW.order_id;
-- select DATEDIFF(day, deli_date, NEW.request_date) INTO date_diff;
select DATE_PART('day', NEW.request_date::timestamp - deli_date::timestamp) into date_diff;
if date_diff > 30 then
		raise exception 'Constraint Violated, refund request date must be within 30 days of the delivery date';
return null;
end if;
return NEW;
end;
$$ language plpgsql;

create constraint trigger refund_constraint2 after insert on refund_request for each row execute function trigger5();

create or replace function trigger6()
returns trigger as $$
declare current_status orderline_status;
begin
	current_status = 'being_processed'; -- Default Value
select orderline.status INTO current_status from orderline where orderline.order_id = NEW.order_id;
if current_status = 'delivered' then
		return NEW;
end if;
	raise exception 'Constraint Violated, Refund Request cannnot be made for an undelivered product';
return null;
end;
$$ language plpgsql;

create trigger refund_constraint3 before insert on refund_request for each row execute function trigger6();

create or replace function trigger7()
returns trigger as $$
declare temp1_id integer;
		temp2_id integer;
begin
select comment.user_id INTO temp1_id from comment where NEW.id = comment.id;
select orders.user_id INTO temp2_id from orders where NEW.order_id = orders.id;
if temp1_id != temp2_id then
		raise exception 'Constraint Violated, user cannot make a review of a product they did not purchase';
return null;
end if;
return new;
end;
$$ language plpgsql;

create trigger comment_constraint1 after insert on review for each row execute function trigger7();

create or replace function trigger8_1()
returns trigger as $$
declare count integer;
begin
select count(*) INTO count from review, reply where review.id = reply.id;
if count > 0 then
		raise exception 'Constraint Violated, Comment must either be a reply or a review';
return null;
end if;
return new;
end;
$$ language plpgsql;

create trigger comment_constraint2 after insert on reply for each row execute function trigger8_1();

create or replace function trigger8_2()
returns trigger as $$
declare count integer;
begin
select count(*) INTO count from review, reply where review.id = reply.id;
if count > 0 then
		raise exception 'Constraint Violated, Comment must either be a reply or a review';
return null;
end if;
return new;
end;
$$ language plpgsql;

create trigger comment_constraint3 after insert on review for each row execute function trigger8_2();

create or replace function trigger9()
returns trigger as $$
declare tally integer;
begin
select count(*) INTO tally from reply_version where reply_version.reply_id = NEW.id;
if tally = 0 then
		raise exception 'Constraint Violated, Reply must have at least one reply version';
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger comment_constraint4 after insert on reply deferrable initially immediate for each row execute function trigger9();

create or replace function trigger10()
returns trigger as $$
declare tally integer;
begin
select count(*) INTO tally from review_version where review_version.review_id = NEW.id;
if tally = 0 then
		raise exception 'Constraint Violated, Review must have at least one review version';
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger comment_constraint5 after insert on review deferrable initially immediate for each row execute function trigger10();

create or replace function trigger11()
returns trigger as $$
declare temp orderline_status;
begin
select orderline.status INTO temp from orderline where orderline.order_id = NEW.order_id;
if temp = 'delivered' then
		return new;
end if;
	raise exception 'Constrainnt Violated, Delivery Complaint can only be made when product has been delivered';
return null;
end;
$$ language plpgsql;

create trigger complaint_constraint1 before insert on delivery_complaint for each row execute function trigger11();

create or replace function trigger12_1()
returns trigger as $$
declare count integer;
begin
select count(*) INTO count from delivery_complaint, shop_complaint, comment_complaint where delivery_complaint.id = shop_complaint.id or delivery_complaint.id = comment_complaint.id or shop_complaint.id = comment_complaint.id;
if count > 0 then
		raise exception 'Constraint Violated, Complaint must either be a comment related, delivery related or shop related' ;
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger complaint_constraint2 after insert on delivery_complaint deferrable initially immediate for each row execute function trigger12_1();

create or replace function trigger12_2()
returns trigger as $$
declare count integer;
begin
select count(*) INTO count from delivery_complaint, shop_complaint, comment_complaint where delivery_complaint.id = shop_complaint.id or delivery_complaint.id = comment_complaint.id or shop_complaint.id = comment_complaint.id;
if count > 0 then
		raise exception 'Constraint Violated, Complaint must either be a comment related, delivery related or shop related' ;
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger complaint_constraint3 after insert on comment_complaint deferrable initially immediate for each row execute function trigger12_2();

create or replace function trigger12_3()
returns trigger as $$
declare count integer;
begin
select count(*) INTO count from delivery_complaint, shop_complaint, comment_complaint where delivery_complaint.id = shop_complaint.id or delivery_complaint.id = comment_complaint.id or shop_complaint.id = comment_complaint.id;
if count > 0 then
		raise exception 'Constraint Violated, Complaint must either be a comment related, delivery related or shop related' ;
return null;
end if;
return new;
end;
$$ language plpgsql;

create constraint trigger complaint_constraint4 after insert on shop_complaint deferrable initially immediate for each row execute function trigger12_3();

---Procedures Main Code
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

---Functions Main Code

-- Qn 2.2 (1)
create or replace function view_comments(shop_id_p INTEGER, product_id_p INTEGER, sell_timestamp_p TIMESTAMP)
    returns table(username TEXT, content TEXT, rating INTEGER, comment_timestamp TIMESTAMP)
    language plpgsql 
    as $$

    #variable_conflict use_column

    begin 
    
    return query

    with recursive all_replies as (
        select r.id, r.other_comment_id from reply r 
		where r.other_comment_id in (select distinct id from relevant_reviews)
        union 
        select r2.id, r2.other_comment_id from reply r2 
        inner join all_replies s on s.id = r2.other_comment_id), 
	
	relevant_reviews as (
    select a.id, b.content, b.rating, b.review_timestamp as comment_timestamp from review a
    inner join review_version b
    on a.id = b.review_id
    where a.shop_id = shop_id_p and a.product_id = product_id_p and a.sell_timestamp = sell_timestamp_p
    and (b.review_id, b.review_timestamp) in (select review_id, max(review_timestamp) as maxR from review a inner join 
							  review_version b on a.id = b.review_id group by review_id)),

    relevant_replies as (
        select a.reply_id as id, a.content, 0 as rating, a.reply_timestamp as comment_timestamp from reply_version a
        where (a.reply_id in (select id from all_replies) or a.reply_id in (select other_comment_id from all_replies)) 
        and a.reply_timestamp in (select max(reply_timestamp) from reply_version group by reply_id)
    ),
	
    joined_table as (select * from relevant_reviews
	union select distinct id, content, rating, comment_timestamp from relevant_replies)
	
	
	select case when (u.account_closed = TRUE) then 'A Deleted User' else u.name end as username, j.content, 
	case when (j.rating = 0) then null else j.rating end as rating, j.comment_timestamp 
	from joined_table j
	inner join comment c 
	on j.id = c.id
	inner join users u
	on c.user_id = u.id
    order by j.comment_timestamp asc, c.id asc; 


    end; $$

;
-- Qn 2.2 (2)

create or replace function get_most_returned_products_from_manufacturer(manufacturer_id INTEGER, n INTEGER)
    returns table(product_id INTEGER, product_name TEXT, return_rate NUMERIC(3, 2))
    language plpgsql 
    
    as $$ 

    #variable_conflict use_column

    begin 

    return query

    with relevant_products as (select id as product_id, name from product  where manufacturer = manufacturer_id),
    
    delivered_orders as (select product_id, count(*) as num_delivered from orderline where 
                            product_id in (select product_id from relevant_products)
                            and status = 'delivered'
                            group by product_id),

    accepted_refunds as (select product_id, count(*) as num_accepted from refund_request where status = 'accepted' 
                        group by product_id),   
						
	final_table as (select a.product_id, a.product_name, coalesce(round(cast(v1 as numeric), 2), 0.00) as return_rate from (
	select product_id, name as product_name, cast(num_accepted as float)/cast(num_delivered as float) as v1 from 
	relevant_products natural left join
	delivered_orders natural left join
	accepted_refunds) a )

	select * from final_table a
	order by a.return_rate desc, a.product_id asc
	limit n
    ;

    end; $$

;

-- Qn 2.2 (3)

create or replace function get_worst_shops(n INTEGER)
    returns table(shop_id INTEGER, shop_name TEXT, num_negative_indicators INTEGER )
    language plpgsql

    as $$
    #variable_conflict use_column

    begin 

    return query

    with refund_count as (select shop_id, count(distinct(order_id, shop_id, product_id, sell_timestamp)) as c1 from refund_request group by shop_id),

    shop_count as (select shop_id, count(id) as c2 from shop_complaint group by shop_id), 

    delivery_count as (select shop_id, count(distinct(order_id, shop_id, product_id, sell_timestamp)) as c3 from delivery_complaint
                        group by shop_id), 

    latest_reviews as (select a.shop_id, count(distinct(a.order_id, a.shop_id, a.product_id, a.sell_timestamp)) as c4 from review a
                        inner join review_version b
                        on a.id = b.review_id
                        where b.rating = 1 and b.review_timestamp in (select max(review_timestamp) from review a inner join review_version b 
                                                    on a.id = b.review_id group by review_id)
                        group by a.shop_id)
						
	select shop_id, shop_name, cast(c1 + c2 + c3 + c4 as INT) as num_negative_indicators from (
    select s.id as shop_id, name as shop_name, coalesce(c1, 0) as c1, coalesce(c2, 0) as c2, coalesce(c3, 0) as c3, coalesce(c4,0) as c4
	from shop s
	left join 
    refund_count r on s.id = r.shop_id
    left join
    shop_count c on s.id = c.shop_id
    left join 
    delivery_count d on s.id = d.shop_id
    left join 
    latest_reviews e on s.id = e.shop_id) a
	order by num_negative_indicators desc
	limit n; 

    end; $$
