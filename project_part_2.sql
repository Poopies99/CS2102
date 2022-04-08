-- Qn 2.2 (1)

drop function if exists view_comments;
drop function if exists get_most_returned_products_from_manufacturer;
drop function if exists get_worst_shops;

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
