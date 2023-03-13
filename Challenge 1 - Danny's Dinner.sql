# Database Creation & Data Insertion
	# Creating Schema
CREATE SCHEMA IF NOT EXISTS dannys_dinner;

	#Creating Sales Table
DROP TABLE IF EXISTS sales;
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
  );
INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11' , '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 
	#Creating Menu Table
DROP TABLE IF EXISTS menu;
CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER 
  );
INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
	#Creating Members Table
DROP TABLE IF EXISTS members;
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);
INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

#01. What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(price)as money_spent 
FROM menu m INNER join sales s 
ON m.product_id = s.product_id
GROUP BY customer_id
ORDER BY customer_id;

#02.How many days has each customer visited the restaurant?
SELECT customer_id,COUNT(DISTINCT order_date) AS num_of_days 
FROM  sales s 
GROUP BY customer_id
ORDER BY customer_id;

#03.What was the first item from the menu purchased by each customer?
WITH first_order AS (
SELECT *,
ROW_NUMBER() OVER(partition by customer_id order by order_date) AS rn
FROM sales )

SELECT customer_id,product_name
FROM first_order f JOIN menu m 
ON m.product_id = f.product_id where rn =1
GROUP BY customer_id,product_name
ORDER BY customer_id;

#04.What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT  m.product_name,COUNT(s.product_id) AS purchase_count
FROM menu m JOIN sales s 
on m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC;


#05.Which item was the most popular for each customer?

WITH popular_item AS (
SELECT customer_id,product_name,COUNT(s.product_id) as order_count,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(s.product_id) DESC) AS rn
FROM menu m join sales s 
on m.product_id = s.product_id
GROUP BY customer_id,product_name
)

SELECT customer_id,product_name,order_count
FROM popular_item WHERE rn = 1;

#06: Which item was purchased first by the customer after they became a member?

WITH first_order AS (
SELECT s.customer_id,product_name,s.order_date,b.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) as rn
FROM menu m JOIN sales s
ON m.product_id = s.product_id
JOIN members b ON b.customer_id = s.customer_id
WHERE order_date >= join_date)

SELECT customer_id,product_name FROM first_order WHERE rn = 1;


#07: #07.Which item was purchased just before the customer became a member?
WITH before_member AS (
SELECT s.customer_id,product_name,s.order_date,b.join_date,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date DESC) as rn
FROM menu m JOIN sales s
ON m.product_id = s.product_id
JOIN members b ON b.customer_id = s.customer_id
WHERE order_date < join_date)

SELECT customer_id,product_name FROM before_member WHERE rn = 1;


#08: What is the total items and amount spent for each member before they became a member?
WITH cte AS (
SELECT s.customer_id,COUNT(s.product_id) AS item_count ,SUM(price) AS amount_spent
FROM sales s JOIN menu m 
ON s.product_id = m.product_id
JOIN members b ON s.customer_id = b.customer_id
WHERE order_date < join_date
GROUP BY s.customer_id)

SELECT * FROM cte;

#09: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, 
SUM(CASE WHEN product_name='sushi' THEN 20*price ELSE 10*price END) AS points
FROM 
sales s JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

#10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
Select s.customer_id, 
SUM(case when m.product_name='sushi' then 20*m.price
when (Extract(Day from s.order_date) -Extract(Day from ms.join_date)) between 0 and 6 then 20*m.price
 else 10*m.price End) as Loyalty_points
from sales s,menu m, members ms
where s.product_id=m.product_id
and s.customer_id =ms.customer_id
and extract(Month from s.order_date) =1
group by s.customer_id
order by s.customer_id;
