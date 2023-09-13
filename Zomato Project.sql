create database zomato;
use zomato;

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

--What is the total amount each customer spent on Zomato?
select a.userid,sum(b.price) as 'total_amount_spent' from sales a 
inner join product b
on a.product_id=b.product_id
group by a.userid;

--How many days has each customer visited zomato?
select userid, count(distinct created_date) as 'distinct_count'
from sales
group by userid;

--What was the first product purchased by each customer?
select * from 
(select *, rank() over(partition by userid order by created_date) as'rank'
from sales) t1
where rank=1;

--What is the most purchased item on the menu and how many times was it purchased by all customers?
--1st part
select top 1 product_id
from sales
group by product_id
order by count(product_id) desc

--2nd part
select userid,count(product_id) as'count'
from sales 
where product_id=
(select top 1 product_id
from sales
group by product_id
order by count(product_id) desc)
group by userid;

--Which item was the most popular for each customer?
select * from
(select userid,product_id,count(product_id) cn,rank() over(partition by userid order by count(product_id) desc) as 'rnk'
from sales
group by userid,product_id) t1
where rnk=1;

--Which item was first purchased by the customer after they became a  member?

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

select * from 
(select *,rank() over(partition by userid order by created_date) rnk 
from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales a 
inner join goldusers_signup b
on a.userid=b.userid
and a.created_date > b.gold_signup_date)t1)t2
where rnk =1;


--ques. which item was purchased just before the customer was a member?
select * from 
(select *,rank() over(partition by userid order by created_date desc) rnk 
from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales a 
inner join goldusers_signup b
on a.userid=b.userid
and a.created_date < b.gold_signup_date)t1)t2
where rnk =1;

--what is the total orders and amount spent for each member before they become a member?
select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

select t1.userid,sum(t2.price) as'sum_price',count(t1.created_date) as 'order_purchased'
from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales a 
inner join goldusers_signup b
on a.userid=b.userid
and a.created_date < b.gold_signup_date)t1
inner join product t2
on t1.product_id=t2.product_id
group by t1.userid;

/*ques if buying each product generates points for eg 5rs=2 zomato points and each product has different purchasing points
for eg for p1 5rs=1 zomato point,for p2 10rs=5 zomato point, p3 5rs = 1 zomato point.
calculate points collected by each customer and for which product max points have been given?
*/

--Part 1
select userid,sum(total_points) as 'total_pointss',sum(total_points) *2.5 as'Money_earned '
from
(select d.*,case
when  d.product_id=1 then total_sum/5
when  d.product_id=2 then total_sum/2
when  d.product_id=3 then total_sum/5
else 0
end as 'total_points' from
(select c.userid,c.product_id,sum(c.price) as 'total_sum' from
(select a.*,b.price from sales a inner join product b on a.product_id=b.product_id)c
group by c.userid,c.product_id)d)e
group by userid;

--Part 2
select top 1 *,rank() over(order by total_points desc) as 'rnk' from
(select product_id,sum(total_points) as 'total_points'
from
(select d.*,case
when  d.product_id=1 then total_sum/5
when  d.product_id=2 then total_sum/2
when  d.product_id=3 then total_sum/5
else 0
end as 'total_points' from
(select c.userid,c.product_id,sum(c.price) as 'total_sum' from
(select a.*,b.price from sales a inner join product b on a.product_id=b.product_id)c
group by c.userid,c.product_id)d)e
group by product_id)f;

/* ques In the first one year after a customer joins the gold program (including their join date) irrespective of what the customer has 
purchased they earn 5 zomato points for every 10rs spent who earned more(1 or 3 member) and what was their points earning 
in their first year*/
--0.5 zomato point=1rs

select t1.*,t2.price,t2.price*0.5 as 'total_points' from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales a 
inner join goldusers_signup b
on a.userid=b.userid
and a.created_date >= b.gold_signup_date and a.created_date<=DATEADD(YEAR,1,b.gold_signup_date))t1
inner join product t2
on t1.product_id=t2.product_id;

/*Rank all the transactions for each member whenever they are a zomato gold member 
for every non gold member transaction mark as NA
*/

select t2.*,case when rnk=0 then 'NA' else rnk end as 'rnkk'
from
(select t1.*,
cast(case
when t1.gold_signup_date is null then 0
else rank() over(partition by userid order by created_date desc)
end as varchar) as 'rnk'
from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales a 
left join goldusers_signup b
on a.userid=b.userid
and a.created_date >= b.gold_signup_date)t1)t2





























