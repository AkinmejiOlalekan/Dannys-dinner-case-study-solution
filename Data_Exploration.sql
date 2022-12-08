--CASE STUDY QUERY



/* QUESTION 1: What is the total amount each customer spent at the restaurant?


From this question, it is essential to use an aggregate function in getting a ‘total’ result and 
also, the sales and menu tables joined together because at least one of the columns from those tables 
are required to get a desired result.
*/
SELECT DISTINCT(customer_id), COUNT(SQLTutorial.dbo.sales.product_id) 
as TotalSales, SUM(price) AS TotalAmt_spent_by_each_Customers
FROM SQLTutorial.dbo.menu 
LEFT JOIN SQLTutorial.dbo.sales
	ON SQLTutorial.dbo.menu.product_id = SQLTutorial.dbo.sales.product_id
GROUP BY customer_id;



/*QUESTION 2: How many days has each customer visited the restaurant?


DISTINCT and COUNT function were both used get the count of the order_date for the unique customers 
who placed an order at Danny’s restaurant.
*/
SELECT DISTINCT(customer_id), COUNT(DISTINCT order_date) 
AS Number_of_days_each_customers_visited
FROM SQLTutorial.dbo.sales
GROUP BY customer_id;



/*QUESTION 3: What was the first item from the menu purchased by each customer?


Getting the first item purchased by each customer, a rank was created which was partitioned by 
customer_id and was ordered by order_date, this was to get the initial date each customer place an 
order and product name was selected to help identify the name of product ordered on their first day. 
This ranking was achieved using the DENSE_RANK function and tables that has the columns required were 
join together using the JOIN function. After the data has been queried written to get how the customers 
place an order with DENSE_RANK function, common table expression (CTEs) was introduced to help manipulate
the complex query data. Also, STRING_AGG function was used to concatenates the rows of string into one
single string by separating it by specified operator.
*/
WITH CTE_first_item_purchased AS
(
SELECT customer_id, product_name, order_date,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
FROM SQLTutorial.dbo.sales as sa
JOIN SQLTutorial.dbo.menu as me
	ON sa.product_id = me.product_id
),
temp_view AS
(
SELECT customer_id, product_name
FROM CTE_first_item_purchased
WHERE order_rank = 1
GROUP BY customer_id, product_name
)
SELECT customer_id, STRING_AGG(product_name, ', ')
FROM temp_view
GROUP BY customer_id;



/*QUESTION 4: What is the most purchased item on the menu and how many times was it purchased by all customers?


In the above question, two questions were asked together and I decided to treat them differently and 
sequentially. Firstly, I wrote a query to find the product name with the highest order by using 
COUNT function. 
*/
SELECT TOP 1(product_name), COUNT(order_date) AS Most_purchased_items
FROM SQLTutorial.dbo.sales
JOIN SQLTutorial.dbo.menu 
	ON SQLTutorial.dbo.menu.product_id = SQLTutorial.dbo.sales.product_id
GROUP BY product_name
ORDER BY Most_purchased_items DESC;
/*
Having discovered that ramen is the most purchased item from Danny’s restaurant, I therefore make use 
of a DENSE_RANK function for product name to get a unique number that stand as a representation of each 
of the items. The use of CTEs help me to manipulate from the query and counted number of times each 
customer ordered ramen. 
*/
WITH CTE_product_purchased_number AS
(
SELECT customer_id, product_name, order_date,
DENSE_RANK() OVER (ORDER BY product_name) AS order_rank
FROM SQLTutorial.dbo.sales as sa
JOIN SQLTutorial.dbo.menu as me
	ON sa.product_id = me.product_id
)
SELECT customer_id, COUNT(order_date) AS total_purchase
FROM CTE_product_purchased_number
WHERE order_rank = 2
GROUP BY customer_id;



/*QUESTION 5: Which item was the most popular for each customer?


CTEs was also used to help manipulate query written to get the most purchased item by each customer. 
DENSE_RANK function was used to assign serial number to the highest counted product_id by incorporating 
COUNT function into the ORDER BY expression and STRING_AGG was used to concatenate rows of product name 
into one single string.
*/
WITH CTE_popular_product AS
(
SELECT customer_id, product_id,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS popularity
FROM sales
GROUP BY customer_id, product_id
)
SELECT customer_id, STRING_AGG(product_name, ', ') WITHIN GROUP (ORDER BY product_name) as most_popular
FROM CTE_popular_product pp
JOIN SQLTutorial.dbo.menu me
	ON pp.product_id = me.product_id
WHERE pp.popularity = 1
GROUP BY customer_id;



/*QUESTION 6: Which item was purchased first by the customer after they became a member?


The thinking, ideology and process followed to answer this question is the same with the previous 
query (question 5), where I make use of common tables expression but the difference here that I make 
use of sub-query to query within a query. Basically, it is used to return data that will be used in 
the main query.
*/
SELECT orders_after_joining.customer_id, me.product_name
FROM 
(SELECT sa.customer_id, sa.product_id, order_date,
DENSE_RANK() OVER (PARTITION BY sa.customer_id ORDER BY order_date) AS days_after_joining
FROM sales sa
JOIN members mem
	ON sa.customer_id = mem.customer_id
WHERE order_date >= join_date
) orders_after_joining
JOIN menu me
	ON orders_after_joining.product_id = me.product_id
WHERE days_after_joining = 1;



/*QUESTION 7: Which item was purchased just before the customer became a member?


This question is similar with question 6 and it was answered using the same procedure.
*/
SELECT customer_id, STRING_AGG(product_name, ', ') AS purchased_before_membership
FROM 
(SELECT sa.customer_id, product_id, order_date,
DENSE_RANK() OVER (PARTITION BY sa.customer_id ORDER BY order_date DESC) AS days_before_joining
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
WHERE order_date < join_date) AS orders_before_joining
JOIN menu me
	ON orders_before_joining.product_id = me.product_id
WHERE days_before_joining = 1
GROUP BY customer_id;
/*
It can also be written like this below to get the same required answer. In the first query, I make use 
of sub-query using the FROM clause while common tables expression (CTEs) was used to answer the same 
case study question using WITH function.
*/
WITH CTE_before_membership AS
(
SELECT sa.customer_id, product_id, order_date,
DENSE_RANK() OVER (PARTITION BY sa.customer_id ORDER BY order_date DESC) AS days_before_joining
FROM sales sa
JOIN members mem
ON sa.customer_id = mem.customer_id
WHERE order_date < join_date
)
SELECT customer_id,
STRING_AGG(product_name, ', ') AS purchased_before_membership
FROM CTE_before_membership bm
JOIN menu me
	ON bm.product_id = me.product_id
WHERE days_before_joining = 1
GROUP BY customer_id, days_before_joining;



/*QUESTION 8: What are the total items and amount spent for each member before they became a member?


This process of writing this query is also similar to question 6’s query. They both follow the same 
pattern. 
*/
SELECT sales_before.customer_id, SUM(no_of_items) as total_items, SUM(price) AS amount_spent
FROM(
SELECT sa.customer_id, price, order_date, COUNT(sa.product_id) AS no_of_items,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS purchase_before_membership
FROM sales sa
JOIN menu
	ON sa.product_id = menu.product_id
GROUP BY customer_id, order_date, price
) sales_before
JOIN members mem
	ON sales_before.customer_id = mem.customer_id
WHERE order_date < join_date
GROUP BY sales_before.customer_id;



/*QUESTION 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier. 
How many points would each customer have?


Let’s break the question down
If $1 = 10points, then every price needs to be multiplied by 10 to get the required points. 
But the product with the name ‘sushi’ has twice the point of every other items which implies 
that $1 = 20points for ‘sushi’.
Here, I was able to make use of CASE statement because it allows to specify condition and also allows
 what to return when the condition is met.
 */
WITH CTE_sales AS
(SELECT customer_id, product_name, price, COUNT(price) AS quantity_purchased,
CASE
	WHEN product_name = 'sushi' THEN (price * COUNT(price)) * 20
	WHEN price >= 1 THEN (price * COUNT(price)) * 10
END AS points
FROM SQLTutorial.dbo.sales sa
JOIN SQLTutorial.dbo.menu mem
	ON mem.product_id = sa.product_id
GROUP BY customer_id, product_name, price
)
SELECT DISTINCT(customer_id), SUM(points) AS points
FROM CTE_sales
GROUP BY customer_id;



/*QUESTION 10: In the first week after a customer joins the program (including their join date) they 
earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of 
January? 


Two new functions were applied here to get desired answer to the case study’s question, DATEADD and 
EOMONTH function. The DATEADD function was used to create a date interval and to get the required point 
earned by each customer within the space of a week after joining member and aggregate total points 
earned at the end of the month. The EOMONTH function was used to set an END OF THE MONTH date to help 
limit the query within the aforementioned month using the WHERE clause.
*/
WITH first_week_cte AS
(SELECT *,
DATEADD(DAY, 6, join_date) as valid_date, EOMONTH('2021-01-31') as  end_of_jan
FROM members),
temp_views as
(
SELECT fw.customer_id, order_date, price,
SUM(CASE 
		WHEN product_name = 'sushi' THEN 20 * price
		WHEN order_date BETWEEN join_date AND valid_date THEN 20 * price
		ELSE 10 * price
	END) AS point
FROM first_week_cte as fw
JOIN sales 
	ON fw.customer_id = sales.customer_id
JOIN menu
	ON sales.product_id = menu.product_id 
WHERE order_date <= end_of_jan
GROUP BY fw.customer_id, order_date, price
)
SELECT customer_id, SUM(point) AS point
FROM temp_views
GROUP BY customer_id;



/*BONUS QUESTION's QUERY

QUESTION 1
*/
SELECT sales.customer_id, order_date, product_name, price, 
CASE 
	WHEN order_date < join_date THEN 'N'
	WHEN order_date >= join_date THEN 'Y'
	ELSE 'N'
END AS member
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
LEFT JOIN members
	ON sales.customer_id = members.customer_id;


/*QUESTION 2
Danny also requires further information about the ranking of customer products, but he purposely does 
not need the ranking for non-member purchases so he expects null ranking values for the records when 
customers are not yet part of the loyalty program
*/
WITH ranking_table_cte AS 
(SELECT sales.customer_id, order_date, product_name, price, 
CASE 
	WHEN order_date < join_date THEN 'N'
	WHEN order_date >= join_date THEN 'Y'
	ELSE 'N'
END AS member
FROM sales
LEFT JOIN menu
	ON sales.product_id = menu.product_id
LEFT JOIN members
	ON sales.customer_id = members.customer_id
)
SELECT customer_id, order_date, product_name, price, member,
CASE
	WHEN member = 'N' THEN NULL
	ELSE DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM ranking_table_cte;
