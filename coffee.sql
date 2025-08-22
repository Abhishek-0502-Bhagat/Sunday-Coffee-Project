-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_consumers_millions,
    city_rank
FROM
    city
ORDER BY 2 DESC;

 -- How many units of each coffee product have been sold?

SELECT 
    p.product_name, COUNT(s.sale_id) AS total_orders
FROM
    products AS p
        JOIN
    sales AS s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY 2 DESC;

-- What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS avg_sale_per_cx
FROM
    sales AS s
        JOIN
    customers AS c ON s.customer_id = c.customer_id
        JOIN
    city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC;

-- Provide a list of cities along with their populations and estimated coffee consumers.

with city_table as
(select city_name,round((population * 0.25) / 1000000, 2) as coffee_customers from city), customers_table as
( select ci.city_name,
count(distinct c.customer_id) as unique_cx
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by city_name)
select ct.city_name,
ct.coffee_customers as coffee_customers_in_millions,
citi.unique_cx
from city_table as ct
join customers_table as citi 
on citi.city_name = ct.city_name;

-- What are the top 3 selling products in each city based on sales volume?


select * from 
(SELECT 
    ci.city_name,
    p.product_name,
    COUNT(s.sale_id) AS total_orders,
    dense_rank() over(partition by ci.city_name order by count(s.sale_id) desc) as ranking
FROM
    sales AS s
        JOIN
    products AS p ON s.product_id = p.product_id
        JOIN
    customers AS c ON c.customer_id = s.customer_id
        JOIN
    city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name , p.product_name) as t1
where ranking <= 3;

-- How many unique customers are there in each city who have purchased coffee products?

select ci.city_name,
count(distinct c.customer_id) as unique_cx
from city as ci
join customers as c
on c.city_id = ci.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ci.city_name;

-- Find each city and their average sale per customer and avg rent per customer.

with city_table as
(SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS avg_sale_per_cx
FROM
    sales AS s
        JOIN
    customers AS c ON s.customer_id = c.customer_id
        JOIN
    city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC),
city_rent as
(select city_name, estimated_rent from city)
select
cr.city_name,
cr.estimated_rent,
ct.total_cx,
ct.avg_sale_per_cx,
round(cr.estimated_rent/ ct.total_cx, 2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc;

-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

with monthly_sales as
(select
ci.city_name,
extract(month from sale_date) as month,
extract(year from sale_date) as year,
sum(s.total) as total_sale
from sales as s
join customers as c
on c.customer_id = s.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1, 2, 3
order by 1, 3, 2),
growth_ratio
as
(select city_name,month,year,
total_sale as cr_month_sale,
lag(total_sale, 1) over(partition by city_name order by year, month) as last_month_sale
from monthly_sales)
select city_name, month, year,
cr_month_sale,
last_month_sale,
round((cr_month_sale-last_month_sale) / last_month_sale * 100, 2) as growth_rate
from growth_ratio
where last_month_sale is not null;

-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer.

with city_table as
(SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2) AS avg_sale_per_cx
FROM
    sales AS s
        JOIN
    customers AS c ON s.customer_id = c.customer_id
        JOIN
    city AS ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC),
city_rent as
(select city_name, estimated_rent, 
round((population *0.25)/1000000, 3) as 
estimated_coffee_consumer_in_millions from city)
select
cr.city_name,
total_revenue,
cr.estimated_rent as total_rent,
ct.total_cx,
estimated_coffee_consumer_in_millions,
ct.avg_sale_per_cx,
round(cr.estimated_rent/ ct.total_cx, 2) as avg_rent_per_cx
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 2 desc;







