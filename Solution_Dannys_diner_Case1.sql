/*
Case Study Questions
1.What is the total amount each customer spent at the restaurant?
2.How many days has each customer visited the restaurant?
3.What was the first item from the menu purchased by each customer?
4.What is the most purchased item on the menu and how many times was it purchased by all customers?
5.Which item was the most popular for each customer?
6.Which item was purchased first by the customer after they became a member?
7.Which item was purchased just before the customer became a member?
8.What is the total items and amount spent for each member before they became a member?
9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January?
*/

-- 1.What is the total amount each customer spent at the restaurant?
select b.customer_id, sum(a.price) as spent
from dannys_diner.menu a
join dannys_diner.sales b on a.product_id = b.product_id
group by b.customer_id
order by b.customer_id;

-- 2.How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date)) as days_visit
from dannys_diner.sales
group by customer_id;

-- 3.What was the first item from the menu purchased by each customer?
-- version 1
with rank_menu_cust as (
select b.customer_id, a.product_name, b.order_date,
dense_rank()
over(partition by b.customer_id order by b.order_date) as ranked
from dannys_diner.menu a 
join dannys_diner.sales b on a.product_id=b.product_id
group by 1,2,3)
select customer_id, product_name from rank_menu_cust
where ranked = 1;

-- version 2
with order_info as (
select b.customer_id, a.product_name, b.order_date,
dense_rank() over(partition by b.customer_id order by b.order_date) as rank_menu
from dannys_diner.menu a 
join dannys_diner.sales b on a.product_id=b.product_id),
first_item as (
select customer_id, product_name
from order_info
where rank_menu = 1
group by 1,2)
select customer_id,
group_concat(distinct product_name order by product_name) as product_name
from first_item
group by 1;

-- 4.What is the most purchased item on the menu and how many times was it purchased 
-- by all customers?
-- version 1
select a.product_name, count(b.product_id) as time_purchased
from dannys_diner.menu a 
join dannys_diner.sales b on a.product_id=b.product_id
group by 1
order by 2 desc
limit 1;

-- version 2
select most_purchased_item, max(count_order) as order_count
from
(select a.product_name as most_purchased_item, count(b.product_id) as count_order
from dannys_diner.menu a
inner join dannys_diner.sales b on a.product_id = b.product_id 
group by 1
order by 2 desc) max_purchased_item;

-- 5.Which item was the most popular for each customer?
-- version 1
with order_info as
(select b.customer_id, 
		a.product_name, 
        count(a.product_name) as order_count,
	rank()over(partition by b.customer_id order by count(a.product_name) desc) as rank_num
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
group by b.customer_id,a.product_name)
select customer_id, product_name
from order_info
where rank_num = 1;

-- version 2
with order_info as
(select b.customer_id, 
		a.product_name, 
        count(a.product_name) as order_count,
	rank()over(partition by b.customer_id order by count(a.product_name) desc) as rank_num
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
group by b.customer_id,a.product_name)
select customer_id,
	   group_concat(distinct product_name order by product_name) as product_name,
       order_count
from order_info
where rank_num=1
group by customer_id;

-- 6.Which item was purchased first by the customer after they became a member?
with dinner_info as
(select 
	a.product_name,
	c.customer_id,
    b.order_date,
    c.join_date,
    b.product_id,
	dense_rank()over(partition by c.customer_id order by b.order_date) as first_item
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
inner join dannys_diner.members c on b.customer_id=c.customer_id
where b.order_date >= c.join_date)
select customer_id,product_name,order_date
from dinner_info
where first_item=1;

-- 7.Which item was purchased just before the customer became a member?
with dinner_info as
(select 
	a.product_name,
	c.customer_id,
    b.order_date,
    c.join_date,
    b.product_id,
	dense_rank()over(partition by c.customer_id order by b.order_date) as item_rank
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
inner join dannys_diner.members c on b.customer_id=c.customer_id
where b.order_date < c.join_date)
select 
	customer_id,
	group_concat(distinct product_name order by product_name) as product_name,
    order_date,
    join_date
from dinner_info
where item_rank=1
group by 1;

-- 8.What is the total items and amount spent for each member before they became a member?

select 
	b.customer_id, 
    count(a.product_name) as total_items,
    concat('$',sum(a.price)) as amt_spent
from dannys_diner.menu a
inner join dannys_diner.sales b on a.product_id=b.product_id
inner join dannys_diner.members c on b.customer_id=c.customer_id 
where b.order_date < c.join_date
group by 1
order by 1;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points 
-- multiplier - how many points would each customer have?

-- before membership
select 
	b.customer_id,
    sum(case 
		when a.product_name = 'sushi' then a.price*20
        else a.price*10
	end) as customer_points
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
group by 1
order by 1;

-- after membership
select 
	b.customer_id,
    sum(case 
		when a.product_name = 'sushi' then a.price*20
        else a.price*10
	end) as customer_points
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
inner join dannys_diner.members c on b.customer_id=c.customer_id
where b.order_date > c.join_date 
group by 1
order by 1;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B 
-- have at the end of January
with prog_last_day as
(select 
	join_date,
    adddate(join_date, interval 6 day) as program_last_date,
    customer_id
from dannys_diner.members)
select 
	b.customer_id,
    sum(case
		when b.order_date between c.join_date and c.program_last_date then a.price*10*2
        when b.order_date not between c.join_date and c.program_last_date
			and a.product_name = 'sushi' then a.price*10*2
		when b.order_date not between c.join_date and c.program_last_date
			and a.product_name != 'sushi' then a.price*10 
		end) as customer_points
from dannys_diner.menu a 
inner join dannys_diner.sales b on a.product_id=b.product_id
inner join prog_last_day c on b.customer_id=c.customer_id 
and b.order_date <= '2021-01-31' and b.order_date >= c.join_date
group by 1
order by 1;

/*
Bonus Questions
Join All The Things
Create basic data tables that Danny and his team can use to quickly derive insights without
needing to join the underlying tables using SQL. Fill Member column as 'N' if the purchase 
was made before becoming a member and 'Y' if the after is amde after joining the membership.
*/

select 
	customer_id,
	order_date,
    product_name,
    price,
    if (order_date>=join_date, 'Y', 'N') as members
from dannys_diner.members a 
right join dannys_diner.sales using (customer_id)
inner join dannys_diner.menu using (product_id)
order by 1,2;

/*
Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he 
expects null ranking values for the records when customers are not yet part of the loyalty program.
*/

select 
	customer_id,
	order_date,
    product_name,
    price,
    if (order_date>=join_date, 'Y', 'N') as members,
    dense_rank()over(partition by customer_id order by order_date) as ranked
from dannys_diner.members 
right join dannys_diner.sales using (customer_id)
inner join dannys_diner.menu using (product_id)
order by 1,2;