-- Monday coffee -- Data Analysis 

-- Reports and Data Analysis

-- Q1- Coffee consumer count
-- How many people in each city are esimated to consume coffee, given that 25% of the population does ?

SELECT 
    city_name,
    ROUND((population * .25) / 1000000, 2) AS coffee_consumer_in_millions,
    city_rank
FROM
    city
ORDER BY 2 DESC;

-- Q2- Total Revenue from Coffee Sales---
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT  ci.city_name,
		SUM(s.total) AS total_revenue
FROM sales as s
JOIN customers as c 
ON s.customer_id = c.customer_id
JOIN city as ci
ON c.city_id = ci.city_id
WHERE EXTRACT(YEAR FROM s.sale_date) = 2023 AND EXTRACT(QUARTER FROM s.sale_date)  = 4
GROUP BY 1
ORDER BY 2 DESC;

-- Q3- Sales count for each product
-- how many units of each coffee products have been sold?

SELECT p.product_name,
		COUNT(*) AS units_sold
FROM sales AS S
LEFT JOIN products AS p 
ON s.product_id = p.product_id
GROUP BY 1 
ORDER BY 2 DESC;

-- Q4- Average Sales Amount per city
-- What is the vaerage sales amount per customer in each city?

SELECT 
		ci.city_name,
        SUM(total) AS total_sales,
        COUNT(DISTINCT s.customer_id) AS total_customer,
        ROUND(SUM(total) / COUNT(DISTINCT s.customer_id),2) AS avg_sales_per_cust
FROM sales AS s
JOIN  customers AS c
ON s.customer_id = c.customer_id
JOIN city AS ci
ON c.city_id = ci.city_id
GROUP BY 1 
ORDER BY 4 DESC;

 
-- Q5 City population and coffee consumers (25%)
-- provide a list of cities with their populatins and estimated coffee consumers
-- return city_name, total current consumers , and estimated coffe consumers

WITH city_table AS
(
SELECT city_name,
		population,
        ROUND((population * 0.25)/1000000,2) AS coffee_consumers_in_millions
FROM city
),
 customer_table AS
(
SELECT 
		ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customer
FROM sales AS s
JOIN customers AS c
ON c.customer_id = s.customer_id
JOIN city AS ci
ON c.city_id = ci.city_id
GROUP BY 1
)
SELECT 
		ct.city_name,
        ct.coffee_consumers_in_millions,
        cit.unique_customer
FROM city_table AS ct
JOIN customer_table AS cit
ON ct.city_name = cit.city_name;

-- Q6- Top selling products by city
-- What are the top 3 selling products in each city based on sales volume?

SELECT * FROM 
(
SELECT 
		ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as Standing
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
JOIN customers AS c
ON c.customer_id = s.customer_id 
JOIN city AS ci
ON ci.city_id = c.city_id
GROUP BY 1,2
) AS t1
WHERE standing <= 3;
-- ORDER BY 1,3

-- Q7 - Customer segmentation by city
-- How many unique customers are there in each city who have purchased coffe products

SELECT 
		ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM city AS ci
    LEFT JOIN 
    customers AS c
    ON c.city_id = ci.city_id
    JOIN sales AS s
    ON s.customer_id = c.customer_id
    WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10.11,12,13,14)
    GROUP BY 1 
    ORDER BY 2;
    
-- Q8 - Average sale Vs Rent
-- Find each city and their average sale per customer and avg rent per customer
 
 WITH city_table
 AS
(
	SELECT 
			ci.city_name,
			COUNT(DISTINCT s.customer_id) AS total_customer,
			ROUND(SUM(total) / COUNT(DISTINCT s.customer_id),2) AS avg_sales_per_cust
	FROM sales AS s
	JOIN  customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON c.city_id = ci.city_id
	GROUP BY 1 
),
city_rent
AS
(
	SELECT city_name,
			estimated_rent 
	FROM city
)
SELECT 
	cr.city_name,
    cr.estimated_rent,
    ct.total_customer,
    ct.avg_sales_per_cust,
    ROUND(cr.estimated_rent / ct.total_customer,2) AS avg_rent_per_cust
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;


-- Q9 - Monthly sales Gorwth rate for each city (Monthly)

WITH monthly_sales 
AS
(
	SELECT 
			ci.city_name,
			EXTRACT(MONTH FROM sale_date) AS month,
			EXTRACT(YEAR FROM sale_date) AS year,
			SUM(s.total) AS total_sale
	FROM sales AS s
	JOIN customers AS c 
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON c.city_id = ci.city_id
	GROUP BY 1,2,3
	ORDER BY 1,3,2
),
growth_ratio
AS
(
	SELECT 
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale,1) OVER (PARTITION BY city_name) AS previous_month_sale
	FROM monthly_sales
)
SELECT city_name,
		month,
        year,
        cr_month_Sale,
        previous_month_sale,
        ROUND((cr_month_sale-previous_month_sale) / previous_month_sale *100, 2) AS growth_ratio
FROM growth_ratio
WHERE previous_month_sale IS NOT NULL;

-- Q10 - Market potential analysis
-- Identidy top 3 cities based on highest sales,return city name,total sale, total rent, total customer, estimated coffe consumers

 WITH city_table
 AS
(
	SELECT 
			ci.city_name,
            SUM(s.total) AS total_revenue,
			COUNT(DISTINCT s.customer_id) AS total_customer,
			ROUND(SUM(total) / COUNT(DISTINCT s.customer_id),2) AS avg_sales_per_cust
	FROM sales AS s
	JOIN  customers AS c
	ON s.customer_id = c.customer_id
	JOIN city AS ci
	ON c.city_id = ci.city_id
	GROUP BY 1 
),
city_rent
AS
(
	SELECT city_name,
			estimated_rent,
            ROUND((population * 0.25)/1000000,2) AS estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
    total_revenue,
    cr.estimated_rent,
    ct.total_customer,
    ct.avg_sales_per_cust,
    ROUND(cr.estimated_rent / ct.total_customer,2) AS avg_rent_per_cust,
    estimated_coffee_consumer_in_millions
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

/*
--Recommendation
City 1 - Pune
	1.Avg rent per customer is very low
    2.highest total revenue,
    3.avg sal per customer is also high
    
City 2 - Delhi
	1.High number of estimated coffee consumers in millions(7.75 Million)
    2.Highest total customers which is 68
    3.avg rent per customer is 300 which is still under 500

City 3 - Jaipur
	1.Highest number of current customers
    2.Average rent per customer is very low which is 156
    3.average sale per customer is better which is 11.6k