-- columns in employees table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'employees';

-- columns in categories table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'categories';

-- columns in customers table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'customers';

-- columns in order_details table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'order_details';

-- columns in orders table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'orders';

-- columns in products table
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'products';

-- timespan of the data: from 1996 to 1998
SELECT DISTINCT EXTRACT(YEAR FROM order_date)
FROM orders;

-- number of employees and their names
SELECT COUNT(DISTINCT employee_id) AS employee_count
FROM employees; -- 9 employees

SELECT CONCAT(first_name, ' ', last_name)
FROM employees;

-- number of products (77 products)
SELECT product_name
FROM products;

-- number of categories (8 categories)
SELECT category_name
FROM categories;

-- number of customers (91 customers)
SELECT company_name
FROM customers;

-- number of ordered distinc products (2155) and distinct order (830)
SELECT *
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id;

SELECT COUNT(DISTINCT orders.order_id)
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id;

-- NULL values? No NULL values for the important columns
SELECT *
FROM order_details
WHERE quantity IS NULL;

SELECT *
FROM order_details
WHERE unit_price IS NULL;

-- negative values? No weird negative values
SELECT *
FROM order_details
WHERE quantity <= 0;

SELECT *
FROM order_details
WHERE unit_price <= 0;

--- creating custom table
CREATE TABLE custom_table AS 
SELECT orders.order_id, orders.order_date, customers.customer_id, customers.company_name, order_details.product_id,
		order_details.unit_price, order_details.quantity, order_details.discount, customers.country
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
LEFT JOIN customers
ON orders.customer_id = customers.customer_id;

--- creating custom table for order_profit
CREATE TABLE order_profit AS
SELECT DISTINCT order_id, order_date, country, customer_id, company_name,
		SUM(ROUND(unit_price * quantity * (1 - discount))) OVER (PARTITION BY order_id, order_date) AS profit
FROM custom_table
ORDER BY 1

-- creating custom_table_2
CREATE TABLE custom_table_2 AS(
	SELECT custom_table.order_id,
	custom_table.order_date,
	custom_table.company_name,
	custom_table.unit_price,
	custom_table.quantity,
	custom_table.discount,
	country,
	product_name,
	category_name
FROM custom_table
LEFT JOIN products
ON custom_table.product_id = products.product_id
LEFT JOIN categories
ON products.category_id = categories.category_id
	)


-- profitablility segmentation (sql)
WITH cte AS (
	SELECT products.product_name, ROUND(SUM(order_details.quantity * order_details.unit_price*(1 - order_details.discount))) AS profit,
	CASE
		WHEN ROUND(SUM(order_details.quantity * order_details.unit_price*(1 - order_details.discount))) >= 15000 THEN 'high_profit'
		WHEN ROUND(SUM(order_details.quantity * order_details.unit_price*(1 - order_details.discount))) BETWEEN 10000 AND 15000 THEN 'average_profit'
		WHEN ROUND(SUM(order_details.quantity * order_details.unit_price*(1 - order_details.discount))) <= 10000 THEN 'low_profit'
		ELSE 'not_segmented'
	END AS profit_segment
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
LEFT JOIN products
ON order_details.product_id = products.product_id
LEFT JOIN categories
ON products.category_id = categories.category_id
GROUP BY products.product_name
	)
	
SELECT product_name, profit, profit_segment,
	COUNT(product_name) OVER (PARTITION BY profit_segment) AS segment_product_count
FROM cte
ORDER BY 4 DESC;

--- average require time (27.88 days)
SELECT ROUND(AVG(required_date - order_date),2) AS avg_require_time
FROM orders


--- countries where delivery speed improvement may be needed
WITH cte AS (
SELECT ship_country,
       ROUND(AVG(required_date - order_date),2) AS avg_require_time_country,
	   (SELECT ROUND(AVG(required_date - order_date),2) AS avg_require_time
FROM orders
	   )
FROM orders
GROUP BY ship_country
	)

SELECT ship_country, avg_require_time_country, avg_require_time,
	CASE
	WHEN avg_require_time_country < avg_require_time THEN 1
	ELSE 0
	END AS requires_faster_delivery
FROM cte
WHERE (
	SELECT
	CASE
	WHEN avg_require_time_country < avg_require_time THEN 1
	ELSE 0
	END AS requires_faster_delivery
) = 1
ORDER BY 2 ASC


--- profit by month from 1996 to 1998 (sql3)
SELECT to_char(order_date, 'Month') AS month,
		ROUND(SUM(quantity * unit_price *(1 - discount))) AS profit
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
GROUP BY month, to_char(order_date, 'mm')
ORDER BY to_char(order_date, 'mm') ASC

--- max profit by month over 1996 till 1998
SELECT *,
	(PERCENT_RANK() OVER (PARTITION BY DATE_TRUNC('month', order_date)::date ORDER BY profit)) * 100 AS percent_rank
FROM order_profit
ORDER BY percent_rank DESC, order_date ASC
LIMIT 23

--- assigning profit scores to distinct orders
SELECT *,
	NTILE(5) OVER (ORDER BY profit ASC) AS profit_score
FROM order_profit
ORDER BY 1

--- best product by profit for each month
SELECT order_date,
	product_name,
	total_profit,
	(PERCENT_RANK() OVER (PARTITION BY DATE_TRUNC('month', order_date)::date ORDER BY total_profit)) * 100 AS percent_rank
FROM product_profit
ORDER BY percent_rank DESC, order_date ASC
LIMIT 23

--- monthly total profit over time 
WITH cte AS(
	SELECT DATE_TRUNC('month', order_date)::date AS order_month,
	SUM(profit) AS total_profit
FROM order_profit
GROUP BY DATE_TRUNC('month', order_date)::date
ORDER BY 1 ASC
	)

SELECT to_char(order_month, 'Mon-YY'), total_profit
FROM cte


--- RFM analysis
--- recency analysis

CREATE TABLE recency_rank AS 
WITH cte_2 AS (
	WITH cte_1 AS (
		SELECT customer_id, 
		order_date,
		MAX(order_date) OVER () AS reference_date
	FROM custom_table
		)

	SELECT customer_id, 
	reference_date - order_date AS days,
		DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY reference_date - order_date) AS customer_recency_rank
	FROM cte_1
	GROUP BY 1, 2
	ORDER BY customer_id ASC
	)

SELECT customer_id,
	DENSE_RANK() OVER (ORDER BY days ASC) AS recency_rank
FROM cte_2
WHERE customer_recency_rank = 1 -- with 1 being the most recent

SELECT *
FROM recency_rank

--- monetary analysis

CREATE TABLE monetary_rank AS (
	WITH cte_2 AS (
		WITH cte AS (
			SELECT customer_id, 
			unit_price, 
			quantity, 
			discount, 
			quantity * unit_price * (1 - discount) AS profit
			FROM custom_table
			)

		SELECT customer_id,
			ROUND(SUM(profit)) AS profit_per_customer
		FROM cte
		GROUP BY customer_id
		ORDER BY 2
		)

	SELECT customer_id, 
		profit_per_customer,
		DENSE_RANK() OVER (ORDER BY profit_per_customer DESC) AS profit_rank
	FROM cte_2
	)

SELECT *
FROM monetary_rank

--- frequency analysis

CREATE TABLE frequency_rank AS (
	WITH cte_1 AS (
		SELECT customer_id,
			COUNT(DISTINCT order_id) AS order_count_per_customer
		FROM custom_table
		GROUP BY customer_id
		ORDER BY 2 DESC
		)

	SELECT customer_id, 
		order_count_per_customer,
		DENSE_RANK() OVER (ORDER BY order_count_per_customer DESC) AS frequency_rank
	FROM cte_1
	)
	
SELECT *
FROM frequency_rank

---

CREATE TABLE rfm_table AS (
	SELECT recency_rank.customer_id, 
		recency_rank, 
		frequency_rank, 
		profit_rank AS monetary_rank
	FROM recency_rank
	INNER JOIN frequency_rank
	On recency_rank.customer_id = frequency_rank.customer_id
	INNER JOIN monetary_rank
	ON recency_rank.customer_id = monetary_rank.customer_id
	)

SELECT *
FROM rfm_table

--- frequency and monetary score

CREATE TABLE company_segment AS (
	WITH freq_mon AS (
	WITH cte_1 AS (
		SELECT customer_id, 
			frequency_rank, 
			monetary_rank,
		DENSE_RANK() OVER (ORDER BY frequency_rank, monetary_rank) AS frequency_monetary_rank
		FROM rfm_table
		ORDER BY frequency_rank, monetary_rank
		)

	SELECT customer_id, 
		frequency_rank, 
		monetary_rank,
		NTILE(3) OVER (ORDER BY frequency_monetary_rank) AS frequency_monetary_ntile
		FROM cte_1),

rec AS (
	SELECT customer_id,
		recency_rank,
		NTILE(3) OVER (ORDER BY recency_rank) AS recency_ntile 
	FROM rfm_table
	)
	
SELECT freq_mon.customer_id, 
	CASE
	WHEN frequency_monetary_ntile = 1 AND recency_ntile = 1 THEN 'champions'
	WHEN frequency_monetary_ntile = 1 AND recency_ntile = 2 THEN 'loyal customers'
	WHEN frequency_monetary_ntile = 1 AND recency_ntile = 3 THEN 'Cant lose them'
	WHEN frequency_monetary_ntile = 2 AND recency_ntile = 1 THEN 'potential loyalist'
	WHEN frequency_monetary_ntile = 2 AND recency_ntile = 2 THEN 'needs attention'
	WHEN frequency_monetary_ntile = 2 AND recency_ntile = 3 THEN 'hibernating'
	WHEN frequency_monetary_ntile = 3 AND recency_ntile = 1 THEN 'price sensitive/promising'
	WHEN frequency_monetary_ntile = 3 AND recency_ntile = 2 THEN 'about to sleep'
	WHEN frequency_monetary_ntile = 3 AND recency_ntile = 3 THEN 'lost'
	END AS predictive_segment	
FROM freq_mon
LEFT JOIN rec
ON freq_mon.customer_id = rec.customer_id
	)

--- profit and discount correlation by month (sql4)
SELECT TO_CHAR(order_date, 'MM') AS month_order, 
	TO_CHAR(order_date, 'Month') AS month, 
	ROUND(SUM(unit_price * quantity * (1 - discount))) AS profit,
	ROUND(AVG(discount * 100)) AS average_discount
FROM custom_table
GROUP BY 1, 2
ORDER BY 1;

--- order count and discount correlation by month (sql5)
SELECT TO_CHAR(order_date, 'MM') AS month_order, TO_CHAR(order_date, 'Month') AS month, 
	COUNT(DISTINCT order_id) AS order_count,
	ROUND(AVG(discount * 100)) AS average_discount
FROM custom_table
GROUP BY 1, 2
ORDER BY 1;


--- correlation between profit and discount with more data points (sql6)
SELECT order_id, 
	COUNT(order_id) AS order_count,
	ROUND(SUM(unit_price * quantity * (1 - discount))) AS profit,
	ROUND(SUM(discount * 100)) AS total_discount
FROM custom_table
GROUP BY 1


--- correlation between order count and profit with more data points (sql7)
SELECT order_date AS order_date, 
	COUNT(order_id) AS order_count,
	ROUND(SUM(unit_price * quantity * (1 - discount))) AS profit
FROM custom_table
GROUP BY 1
ORDER BY 1;


--- profit by product (sql8)
SELECT product_name,
	ROUND(SUM(unit_price * quantity * (1 - discount))) AS profit
FROM custom_table_2
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

---- profit by category (sql9)
SELECT category_name,
	ROUND(SUM(unit_price * quantity * (1 - discount))) AS profit
FROM custom_table_2
GROUP BY 1
ORDER BY 2 DESC;

--- fastest employees
SELECT CONCAT(first_name, ' ', last_name),
	ROUND(AVG(quantity)) AS products_to_ship,
	ROUND(AVG(shipped_date - order_date)) AS days_till_shipping
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
LEFT JOIN employees
ON orders.employee_id = employees.employee_id
GROUP BY CONCAT(first_name, ' ', last_name)
ORDER BY 3 ASC, 2 DESC;


--- product with profit decrease compared to the previous year (sql11)
WITH cte_2 AS (
	WITH cte AS (
	SELECT product_name, 
		EXTRACT(YEAR FROM order_date) AS year,
		ROUND(AVG(quantity * unit_price * (1 - discount))) AS avg_profit
FROM custom_table_2
GROUP BY product_name, year
ORDER BY 1, 2
	)

SELECT *,
	LAG(avg_profit) OVER (PARTITION BY product_name ORDER BY year) AS previous_profit
FROM cte
WHERE year = 1998 OR year = 1997
	)
	
SELECT product_name, 
	avg_profit, 
	previous_profit, 
	ROUND(100*(avg_profit - previous_profit) / previous_profit) AS percentage_decrease
FROM cte_2
WHERE avg_profit < previous_profit
ORDER BY 4;

-- what is our customer profile? US, Germany and France are our biggest markets (sql12)
SELECT country, 
	COUNT(customer_id) AS country_count
FROM customers
GROUP BY country
ORDER BY 2 DESC;

-- what is the category distribution? Confections, condiments, beverages and seafood are most of our products. (sql13)
SELECT category_name,
	COUNT(product_name) AS product_count
FROM products
LEFT JOIN categories
ON products.category_id = categories.category_id
GROUP BY category_name
ORDER BY 2 DESC;

-- Top 10 most profitable products in 1998 (sql14)
SELECT products.product_name, 
	ROUND(SUM(order_details.unit_price * order_details.quantity * (1 - discount))) AS product_sale
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
LEFT JOIN products
ON order_details.product_id = products.product_id
WHERE EXTRACT(YEAR FROM order_date) = 1998
GROUP BY 1 
ORDER BY product_sale DESC
LIMIT 10;

-- Top 10 most ordered products in 1998 (sql15)
SELECT products.product_name,
	SUM(order_details.quantity) AS product_order_count
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
LEFT JOIN products
ON order_details.product_id = products.product_id
WHERE EXTRACT(YEAR FROM order_date) = 1998
GROUP BY 1
ORDER BY product_order_count DESC
LIMIT 10;

-- profit change over time (sql16)
WITH cte AS (
	SELECT DATE_TRUNC('month', order_date)::date AS year_month,
	SUM(profit) AS total_profit
FROM order_profit
GROUP BY 1
ORDER BY 1 ASC
	)

SELECT *,
	LAG(total_profit) OVER (ORDER BY year_month) AS previous_profit,
	100 * (ROUND((total_profit / LAG(total_profit) OVER (ORDER BY year_month))::numeric, 2) - 1) AS profit_change
FROM cte
WHERE year_month BETWEEN '1997-04-01' AND '1998-05-01';

--- ultimate table for powerbi
SELECT orders.order_id,
	orders.order_date,
	orders.required_date,
	orders.shipped_date,
	products.product_name,
	categories.category_name,
	order_details.unit_price,
	order_details.quantity,
	order_details.discount,
	customers.company_name,
	customers.country,
	CONCAT(first_name, ' ', last_name) AS employee_name,
	suppliers.supplier_id
FROM orders
LEFT JOIN order_details
ON orders.order_id = order_details.order_id
LEFT JOIN products
ON order_details.product_id = products.product_id
LEFT JOIN employees
ON orders.employee_id = employees.employee_id
LEFT JOIN suppliers
ON products.supplier_id = suppliers.supplier_id
LEFT JOIN categories
ON products.category_id = categories.category_id
LEFT JOIN customers
ON orders.customer_id = customers.customer_id


