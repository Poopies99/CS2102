drop trigger product_constraint on product;
drop trigger order_constraint on orderline;
drop trigger coupon_constraint on orders;
drop trigger refund_constraint1 on refund_request;
-- drop trigger refund_constraint2 on refund_request;
drop trigger refund_constraint3 on refund_request;
drop trigger comment_constraint1 on review;
drop trigger comment_constraint2 on comment;
drop trigger comment_constraint3 on reply;
drop trigger comment_constraint4 on review;
drop trigger complaint_constraint1 on delivery_complaint;

-- Check with Prof
create or replace function trigger1()
returns trigger as $$
declare count integer;
begin
	count = 0;
	select count(*) INTO count from sells, shop where shop.id = sells.shop_id;
	if count = 0 then 
		raise notice 'Contraint Violated,  Each shop needs to sell at least one product.';
		-- return null;
		return new;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger product_constraint before insert on product for each row execute function trigger1();

-- As long as product id exists in orderline, then 
create or replace function trigger2()
returns trigger as $$
declare count integer;
begin
	count = 0;
	select count(*) INTO count from orderline where NEW.order_id = orders.id;
	if count = 0 then
		raise notice 'Constraint Violated, Each order must involve one or more products';
		return null;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger order_constraint before insert on orderline for each row execute function trigger2();

create or replace function trigger3()
returns trigger as $$
declare min_amt numeric;
begin
	min_amt = 0;
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
	refund_qty = NEW.quantity;
	order_qty = 0;
	select orderline.quantity INTO order_qty from orderline where orderline.order_id = NEW.order_id;
	if order_qty < refund_qty then
		raise exception 'Constraint Violated, sum of quantity of refunds exceeds order quantity';
		return null;
	end if;
	return NEW;
end;
$$ language plpgsql;

create trigger refund_constraint1 before insert on refund_request for each row execute function trigger4();

/* Problem
create or replace function trigger5()
returns trigger as $$
declare req_date date;
		deli_date date;
		date_diff integer;
begin
	req_date = NEW.request_date;
	deli_date = '2016-06-23';
	date_diff = 0;
	select orderline.delivery_date INTO deli_date from orderline where orderline.order_id = NEW.order_id;
	if (select DATE_PART('day', req_date - deli_date) > 30 ) then
		raise exception 'Constraint Violated, refund request date must be within 30 days of the delivery date';
		return null;
	end if;
	return NEW;
end;
$$ language plpgsql;

create trigger refund_constraint2 before insert on refund_request for each row execute function trigger5();
*/

create or replace function trigger6()
returns trigger as $$ 
declare current_status orderline_status;
begin
	current_status = 'being_processed'; -- Any enum value that is not delivered is also fine
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
	temp1_id = 0;
	temp2_id = 0;
	select comment.user_id INTO temp1_id from comment where NEW.id = comment.id;
	select orders.user_id INTO temp2_id from orders where NEW.order_id = orders.id;
	if temp1_id = temp2_id then 
		return NEW;
	end if;
	raise exception 'Constraint Violated, user cannot make a review of a product they did not purchase';
	return null;
end;
$$ language plpgsql;

create trigger comment_constraint1 before insert on review for each row execute function trigger7();

create or replace function trigger8()
returns trigger as $$
begin
	if exists (select 1 from review where review.id = NEW.id and exists (select 1 from reply where reply.id = NEW.id)) then
		raise exception 'Constraint Violated, Comment must either be a reply or a review';
		return null;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger comment_constraint2 before insert on comment for each row execute function trigger8();

create or replace function trigger9()
returns trigger as $$
declare tally integer;
begin
	tally = 0;
	select count(*) INTO tally from reply_version where reply_version.reply_id = NEW.id;
	if tally = 0 then 
		raise exception 'Constraint Violated, Reply must have at least one reply version';
		return null;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger comment_constraint3 before insert on reply for each row execute function trigger9();

create or replace function trigger10()
returns trigger as $$
declare tally integer;
begin
	tally = 0;
	select count(*) INTO tally from review_version where review_version.review_id = NEW.id;
	if tally = 0 then
		raise exception 'Constraint Violated, Review must have at least one review version';
		return null;
	end if;
	return new;
end;
$$ language plpgsql;

create trigger comment_constraint4 before insert on review for each row execute function trigger10();

create or replace function trigger11()
returns trigger as $$
declare temp orderline_status;
begin
	temp = 'being_processed';
	select orderline.status INTO temp from orderline where orderline.order_id = NEW.order_id;
	if temp = 'delivered' then
		return new;
	end if;
	raise exception 'Constrainnt Violated, Delivery Complaint can only be made when product has been delivered';
	return null;
end;
$$ language plpgsql;

create trigger complaint_constraint1 before insert on delivery_complaint for each row execute function trigger11();

/*
create or replace function trigger12()
returns trigger as $$
begin
	if exists (select 1 from NEW.id = )
*/















