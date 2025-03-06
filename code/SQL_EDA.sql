-- Add 1 more column serving as an unique key for the table
ALTER TABLE all_orders
ADD COLUMN id INT auto_increment primary KEY;

-- Update Null values in total_before_discount
UPDATE all_orders
SET total_before_discount = total_after_discount
WHERE total_before_discount IS NULL;

-- Add supplier id
ALTER TABLE all_orders
ADD COLUMN supplier_id INT; -- This column will initially have NULL values for all rows

-- Assign supplier_id to each supplier
UPDATE all_orders a
JOIN (
    SELECT supplier, 
    DENSE_RANK() OVER (ORDER BY supplier) AS rank_id -- Assigns a unique number to each supplier unique number
    FROM all_orders
) ranked ON a.supplier = ranked.supplier
SET a.supplier_id = ranked.rank_id;


SELECT * FROM all_orders;

-- How many orders were placed each year
SELECT 
	COUNT(DISTINCT order_id) AS total_orders, 
	YEAR(date) AS year
FROM all_orders
GROUP BY YEAR(date)
ORDER BY 2;

-- How many orders were placed each quarter and year
SELECT 
	COUNT(DISTINCT order_id) AS total_orders, 
    QUARTER(date) AS quarter,
	YEAR(date) AS year
FROM all_orders
GROUP BY YEAR(date), QUARTER(date)
ORDER BY 3, 2;

-- Which months had the highest/lowest number of orders (excluding 2022 and 2025 since they don't have enough months for comparison)?
SELECT 
	COUNT(DISTINCT order_id) AS total_orders, 
    MONTH(date) AS month
FROM all_orders
WHERE YEAR(date) IN (2023, 2024)
GROUP BY 2
ORDER BY 1 DESC;

-- How often do I place orders on monthly average
WITH total_months_each_year AS (
	SELECT 
		YEAR(date) AS year, 
		COUNT(DISTINCT MONTH(date))  AS total_month
    FROM all_orders 
    GROUP BY YEAR(date)
    )
, total_orders_each_year AS (
	SELECT
		COUNT(DISTINCT order_id) as total_orders,
		YEAR(date) as year
	FROM all_orders
	GROUP BY 2
    )
SELECT 
	t1.year,
    t1.total_month,
    t2.total_orders,
    t2.total_orders/t1.total_month AS AVG_order_permonth
FROM total_months_each_year t1
JOIN total_orders_each_year t2 ON t1.year = t2.year
ORDER BY 1;

-- What is the longest/shortest gap between orders?
WITH CTE AS (
	SELECT DISTINCT order_id, date FROM all_orders 
)
SELECT
    date,
    LAG(date, 1, 0) OVER(ORDER BY date) AS last_order_day,
    DATEDIFF(date, LAG(date, 1, 0) OVER(ORDER BY date)) AS day_gap
FROM CTE
ORDER BY 3 DESC;

-- How much was spent anually on orders
SELECT 
	ROUND(SUM(total_after_discount), 2) AS total_spent,
    year,
	quarter
FROM (
SELECT 
	DISTINCT order_id,
    YEAR(date) as year,
    QUARTER(date) as quarter,
    total_after_discount
FROM all_orders
) AS tbl
GROUP BY 2, 3
ORDER BY 2, 3;

-- Total spent on all orders
SELECT 
	ROUND(SUM(total_after_discount), 2) AS total_spent
FROM (
SELECT 
	DISTINCT order_id,
    total_after_discount
FROM all_orders
) AS tbl
ORDER BY 1 DESC;

-- What is the average amount spent per order
SELECT
	ROUND(AVG(total_after_discount), 2) AS AVG_spent_per_order,
    year
FROM (
SELECT
	DISTINCT order_id,
    YEAR(date) as year,
    total_after_discount
FROM all_orders
) AS tbl
GROUP BY 2;

-- Most and least expensive order
SELECT MAX(total_after_discount) AS most_expensive_order, MIN(total_after_discount) AS least_expensive_order FROM all_orders;

-- Are there specific suppliers I frequently purchase from? How many items I have bought in total? What is the total amount of discount I have from this supplier?
WITH CTE AS (
	SELECT 
		DISTINCT order_id,
        supplier_id,
        total_after_discount
	FROM all_orders
    )
, total_spent_each_supplier AS (
	SELECT
		supplier_id,
        SUM(total_after_discount) AS total_spent
	FROM CTE
    GROUP BY 1)
, discount_each_supplier AS (
SELECT
	DISTINCT order_id,
    supplier_id,
    total_before_discount - total_after_discount AS total_discount
FROM all_orders
)
, total_discount AS (
	SELECT 
		supplier_id,
		SUM(total_discount) AS total_discount
	FROM discount_each_supplier
	GROUP BY 1)
SELECT
	t1.supplier_id,
    t1.supplier,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(*) AS total_items,
    ROUND(t2.total_spent, 2) AS total_spent,
    ROUND(t3.total_discount, 2) AS total_discount
FROM all_orders t1
JOIN total_spent_each_supplier t2 ON t1.supplier_id = t2.supplier_id
JOIN total_discount t3 ON t3.supplier_id = t1.supplier_id
GROUP BY 1, 2
ORDER BY 3 DESC;

SELECT * FROM all_orders;

-- Total discount each year
SELECT 
	SUM(total_discount) AS total_discount,
    year
FROM (
SELECT
	DISTINCT order_id,
	total_before_discount - total_after_discount AS total_discount,
    YEAR(date) as year
FROM all_orders
) AS tbl GROUP BY 2;

-- What is the average items per order each year
SELECT
	YEAR(date),
    COUNT(*) AS num_of_items,
    COUNT(DISTINCT order_id) AS num_of_orders,
    COUNT(*) / COUNT(DISTINCT order_id) AS AVG_items_per_order
FROM all_orders
GROUP BY 1;





