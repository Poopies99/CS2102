drop trigger shop_constraint on sells;
drop trigger order_constraint on orderline;
drop trigger coupon_constraint on orders;
drop trigger refund_constraint1 on refund_request;
drop trigger refund_constraint2 on refund_request;
drop trigger refund_constraint3 on refund_request;
drop trigger comment_constraint1 on review;
drop trigger comment_constraint2 on reply;
drop trigger comment_constraint3 on review;
drop trigger comment_constraint4 on reply;
drop trigger comment_constraint5 on review;
drop trigger complaint_constraint1 on delivery_complaint;
drop trigger complaint_constraint2 on delivery_complaint;
drop trigger complaint_constraint3 on comment_complaint;
drop trigger complaint_constraint4 on shop_complaint;

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

create constraint trigger shop_constraint after insert on sells deferrable initially deferred for each row execute function trigger1();

create or replace function trigger2()
returns trigger as $$
declare count_unique integer;
		count_order integer;	
begin
	select count(distinct orders.id) INTO count_unique from orders join orderline on orders.id = orderline.shop_id;
	select count(distinct orders.id) INTO count_order from orders;
	if count_order > count_unique then
		raise notice 'Constraint Violated, Each order needs to include one or more product';
		return null;
	end if;
	return new;
end;
$$ language plpgsql;

create constraint trigger order_constraint after insert on orderline deferrable initially deferred for each row execute function trigger2();

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

create constraint trigger comment_constraint4 after insert on reply deferrable initially deferred for each row execute function trigger9();

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

create constraint trigger comment_constraint5 after insert on review deferrable initially deferred for each row execute function trigger10();

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

create constraint trigger complaint_constraint2 after insert on delivery_complaint deferrable initially deferred for each row execute function trigger12_1();

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

create constraint trigger complaint_constraint3 after insert on comment_complaint deferrable initially deferred for each row execute function trigger12_2();

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

create constraint trigger complaint_constraint4 after insert on shop_complaint deferrable initially deferred for each row execute function trigger12_3();
