/*Creating view 1*/
CREATE VIEW AllTables AS
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
 /*using the case statment to find customers who are (or not) member of Danny’s Diner loyalty program*/
 CASE
  WHEN sales.order_date >= members.join_date THEN 'Y'
  ELSE 'N'
  END AS member
FROM sales
JOIN
menu
ON sales.product_id = menu.product_id
FULL OUTER JOIN members
ON sales.customer_id = members.customer_id

SELECT*
FROM Alltables

/*CREATE VIEW 2 FOR PARTIAL*/ 

CREATE OR ALTER VIEW PartialTable AS
SELECT sales.customer_id, sales.order_date, Join_date, menu.product_name, menu.price,
 /*using the case statment to find customers who are (or not) member of Danny’s Diner loyalty program*/
 CASE
  WHEN sales.order_date >= members.join_date THEN 'Y'
  ELSE 'N'
  END AS member
FROM sales
JOIN
menu
ON sales.product_id = menu.product_id
FULL OUTER JOIN members
ON sales.customer_id = members.customer_id


/*Total amount each customer spent*/
SELECT customer_id, SUM(price) AS CustomerTotalSpent
FROM AllTables
GROUP BY customer_id

/*Numbers of days each customers has visited the restaurant*/
SELECT customer_id, COUNT(DISTINCT order_date) As CustomerTotalVisit
FROM AllTables
GROUP BY customer_id

/*First item purchased by each customer*/
SELECT DISTINCT allt.customer_id, allt.product_name
FROM AllTables allt
WHERE order_date = (SELECT MIN(alltb.order_date)
FROM AllTables alltb)
ORDER BY allt.customer_id

/*The most purchased item on the menu and number of times was it purchased by all customers*/
SELECT Top 1 product_name, COUNT(product_name) As TotalProductSales
FROM AllTables
GROUP BY product_name
ORDER BY 2 DESC

/*Most Popular Items by each customer*/
WITH PopularItems AS(
    SELECT customer_id, product_name, COUNT(order_date) As total,
    RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) AS product_rank
    FROM AllTables
    GROUP BY customer_id, product_name)
SELECT customer_id, product_name
FROM PopularItems
WHERE product_rank = 1

/*item purchased first by customers after they became a member*/
WITH FirstPurchased AS (
SELECT customer_id, product_name, MIN(order_date) AS ordered_date,
RANK () OVER (PARTITION BY customer_id ORDER BY MIN(order_date)) AS ARank
FROM AllTables 
WHERE member = 'Y'
GROUP BY customer_id, product_name)
SELECT customer_id, product_name
FROM FirstPurchased
WHERE ARANK = 1

/*Item purchased just before the customer became a member*/
WITH LastPurchased AS (
SELECT customer_id, product_name, MAX(order_date) AS ordered_date,
RANK () OVER (PARTITION BY customer_id ORDER BY MAX(order_date) DESC) AS ARank
FROM PartialTable
WHERE member = 'N' AND join_date is Not NULL
GROUP BY customer_id, product_name)
SELECT customer_id, product_name
FROM LastPurchased
WHERE ARank = 1

/* Total items and amount spent for each member before they Became a member*/

SELECT customer_id, COUNT(product_name) As Totalproduct, SUM(price) AS Total
FROM PartialTable
WHERE member = 'N' AND join_date is Not NULL
GROUP BY customer_id


/*If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?*/

WITH GiftPont AS(
SELECT product_id, product_name,
CASE WHEN product_id = 1 THEN price * 20
ELSE price * 10
END AS point
FROM menu)
SELECT customer_id, SUM(point) AS Totalpoint
FROM sales s
join
GiftPont G
ON s.product_id = G.product_id
GROUP BY customer_id
ORDER BY customer_id


/*Bonus 2; Rank all things*/
SELECT *, 
CASE 
WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date) 
ELSE null END AS ranking
FROM AllTable

/*10*/
WITH dates_cte AS(
	SELECT *, 
		DATEADD(DAY, 6, join_date) AS valid_date, 
		EOMONTH('2021-01-1') AS last_date
	FROM members
)

SELECT
	s.customer_id,
	sum(CASE
		WHEN s.product_id = 1 THEN price*20
		WHEN s.order_date between d.join_date and d.valid_date THEN price*20
		ELSE price*10 
	END) as Totaloints
FROM
	dates_cte d,
	sales s,
	menu m
WHERE
	d.customer_id = s.customer_id
	AND
	m.product_id = s.product_id
	AND
	s.order_date <= d.last_date
GROUP BY s.customer_id;