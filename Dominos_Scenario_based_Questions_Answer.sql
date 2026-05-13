-- Dominos Store Project
-- Analysis & Reports

1.Orders Volume Analysis Queries
Stakeholder(Operations Manager)

/* 
"we are trying to understand our order volume in details so we can measure store performance and benchmark growth.
Istead of just knowing the total number of unique orders,I'd like a deeper breakdown.

- What is the total number of unique orders placed so far ?
- How can this order volume changed month-over-month?
- Can we identify peak and off-peak ordering days?
- How do order volumes vary by day of the week(e.g, weekends vs weekdays)?
- What is the average number of orders per customers ?
- Who are our top repeat customers driving the order volume?
- can you also project the expected order growth trend based on historical data?
"
*/

-- Analyst Tasks:

--1.Count the total number of unique orders.
SELECT COUNT(DISTINCT order_id) AS total_unique_order
FROM orders;

--2.Break down orders by month-over-month.
"""
MoM Growth %:

MoM Growth % = (Current Month Orders−Previous Month Orders/Previous Month Orders) X 100

"""
WITH monthly_orders AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY 1
),
mom_calc AS (
    SELECT
        month,
        order_count,
        LAG(order_count) OVER (ORDER BY month) AS prev_month_orders
    FROM monthly_orders
)

SELECT
    month,
    order_count,
    prev_month_orders,
    ROUND(
        100.0 * (order_count - prev_month_orders)
        / NULLIF(prev_month_orders, 0),
        2
    ) AS mom_growth_pct
FROM mom_calc
ORDER BY month;


--3.Find day-wise order distribution.
SELECT
    TRIM(TO_CHAR(order_date, 'Day')) AS weekday,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY 1,
         EXTRACT(DOW FROM order_date)
ORDER BY EXTRACT(DOW FROM order_date);

--4.Compute average orders per customer.
WITH customer_orders AS (
    SELECT 
        custId,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY custId
),
stats AS (
    SELECT
        AVG(total_orders) AS avg_orders_per_customer,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_orders) AS median_orders,
        MAX(total_orders) AS max_orders,
        MIN(total_orders) AS min_orders
    FROM customer_orders
)
SELECT 
    ROUND(avg_orders_per_customer, 2) AS avg_orders_per_customer,
    median_orders,
    max_orders,
    min_orders
FROM stats;


--5.Identify repeat customers and their order frequency.
SELECT 
    custId,
    COUNT(order_id) AS total_orders,
    MIN(order_date) AS first_order,
    MAX(order_date) AS last_order
FROM orders
GROUP BY custId
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;



--6.Use window function to calculate month-over-month growth % .
WITH monthly_orders AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY 1
),
lagged AS (
    SELECT
        month,
        order_count,
        LAG(order_count) OVER (ORDER BY month) AS prev_month_orders
    FROM monthly_orders
)

SELECT
    month,
    order_count,
    prev_month_orders,
    ROUND(
        100.0 * (order_count - prev_month_orders)
        / NULLIF(prev_month_orders, 0),
        2
    ) AS mom_growth_pct
FROM lagged
ORDER BY month;

--7.Build a trend projection using cumulative counts or forcasting methods.
WITH monthly_orders AS (
    SELECT 
        DATE_TRUNC('month', order_date) AS month,
        COUNT(order_id) AS order_count
    FROM orders
    GROUP BY 1
)

SELECT
    month,
    order_count,

    SUM(order_count) OVER (ORDER BY month) AS cumulative_orders
FROM monthly_orders
ORDER BY month;



2.Total Revenue from pizza Sales
Stakeholder (Finance Team).

/*
"we need to report monthly revenue to management.
Can you calculate the total revenue generated from all pizza sales,
considering price * quantity from each order ?"

Analyst Task : Join order_details with pizzas and sum (price * quantity)
*/

--Query
SELECT * FROM order_details;
SELECT * FROM pizzas;

SELECT 
    TO_CHAR(o.order_date, 'YYYY-MM') AS month,
    SUM(od.quantity * p.price) AS total_revenue
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN pizzas p ON od.pizza_id = p.pizza_id
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM')
ORDER BY month;

3.Highest-Priced Pizza

Stakeholder (Menu Manager):
/*
"Our premium pizzas must be correctly priced.Can you find out which pizza
has the highest price on our menu and confirm its category and size?"

Analyst Task : Query the pizzas table for the maximum price,joining with pizza_types for details.
*/

--Query
SELECT 
    pt.name,
    p.size,
    CONCAT('$', p.price) AS price
FROM pizzas p
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;



4. Most Common Pizza size Ordered
Stakeholder(Logistics Managers)

/*
"To optimize packaging and raw material supply, I need to known which
pizza size (S,M,L,,XL,XXL) is ordered the most"

Analyst Task : Count and group by pizza size from pizzas * order_details.
*/

--Query
WITH size_orders AS (
    SELECT 
        p.size,
        COUNT(*) AS total_orders
    FROM order_details od
    JOIN pizzas p 
        ON od.pizza_id = p.pizza_id
    GROUP BY p.size
)
SELECT 
    size,
    total_orders,
    DENSE_RANK() OVER (ORDER BY total_orders DESC) AS size_rank
FROM size_orders;



5.Top 5 Most Ordered Pizza Types
Stakeholder(Product Head)

/*
"We want to promote our top-selling pizzas.Can you provude the top 5 pizza
types ordered by quantity,along with the exact number of units sold?"

Analyst Task: Join order_details with pizza_types,group by pizza name, and rank top 5.
*/


--Query
SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity) AS total_units_sold
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_units_sold DESC
LIMIT 5;

6. Total Quantity by pizza Category
stakeholder (Marketing Manager)

/*
"we run promotions based on categories(classic,veggie,Supreme,chicken,etc).
can you calculate the total number of pizzas sold in each category
so we can plan targeted campaigns?"

Analyst Task: join pizzas with pizza_type and sum quantities by category
*/

--Query
SELECT 
    pt.category,
    SUM(od.quantity) AS total_pizzas_sold
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY total_pizzas_sold DESC;

7. Order by Hour of the Day
Stakeholder (Operations Head):

/*
"when are customers ordering the most? Do they prefer launch (12-2 PM),
evening(6-9 PM),or last-night ? Please give me a distribution of order
by hour of the day so we can adjust staffing."

Analyst Task : Extract the hour from the order_time in orders table and count frequency.
*/
-- Query

SELECT 
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;

-- to_char
SELECT 
    TO_CHAR(order_time, 'HH24:00') AS hour_label,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY TO_CHAR(order_time, 'HH24:00')
ORDER BY TO_CHAR(order_time, 'HH24:00');


8. Category-wise pizza Distribution
Stakeholder(Product Strategy Team):

/*
"Which categories(like veggie,chicken,Supreme) dominate
our menu sales ? can you prepare a breakdown of orders per category with percentage share?"

Analyst Task : Join tables and calculate share of each category.
*/

--Query
WITH category_sales AS (
    SELECT 
        pt.category,
        SUM(od.quantity) AS total_pizzas_sold
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category
),
total_sales AS (
    SELECT SUM(total_pizzas_sold) AS grand_total
    FROM category_sales
)

SELECT 
    cs.category,
    cs.total_pizzas_sold,
    ROUND(
        (cs.total_pizzas_sold * 100.0 / ts.grand_total), 
        2
    ) AS percentage_share
FROM category_sales cs
CROSS JOIN total_sales ts
ORDER BY cs.total_pizzas_sold DESC;


9. Average pizzas Ordered per Day
stakeholder(CEO):
/*
"I want to see if our daily demand is consistent.
can you group orders by date and tell me the average number of pizzas ordered per day?"

Analyst Task: Aggregate by order_date,calculate total pizzas per day,then average.
*/

--Query
WITH daily_orders AS (
    SELECT 
        DATE(order_time) AS order_date,
        SUM(od.quantity) AS total_pizzas_per_day
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY DATE(order_time)
)

SELECT 
    order_date,
    total_pizzas_per_day,
    AVG(total_pizzas_per_day) OVER () AS avg_daily_pizzas
FROM daily_orders
ORDER BY order_date;


10.Top 3 pizzas by Renenue
Stakeholder(Finance Team)

/*
"we need to know which pizzas are our biggest revenue drivers.
Please provides the top 3 pizzas by revenue generated"

Analyst Analysis: Calculated revenue per pizza(price * quantity) and rank top 3.
*/

-- Query
WITH pizza_revenue AS (
    SELECT 
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS total_revenue
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.name
),
ranked_pizzas AS (
    SELECT *,
           RANK() OVER (ORDER BY total_revenue DESC) AS rnk
    FROM pizza_revenue
)

SELECT *
FROM ranked_pizzas
WHERE rnk <= 3;

11.Revenue Contribution per pizza
Stakeholder(CFO)
/*
"For our revenue mix analysis,I need to known what percentage of 
total revenue each pizzas contributes.
This will show which items carry the business.

Analyst Task: Divide revenue of each pizza by total rvenue,express in %;"
*/

--Query
WITH pizza_revenue AS (
    SELECT 
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS revenue
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.name
),

total_revenue AS (
    SELECT SUM(revenue) AS total_rev
    FROM pizza_revenue
)

SELECT 
    pr.pizza_name,
    pr.revenue,
    ROUND((pr.revenue * 100.0 / tr.total_rev), 2) AS revenue_percentage
FROM pizza_revenue pr
CROSS JOIN total_revenue tr
ORDER BY revenue_percentage DESC;

12.Cumulative Revenue Over Time.
Stakeholder(Board of Director)
/*
"We want to see how cumulative revenue has grown month by month
Since launch.Can you prepare a cumulative revenue trend line?"

Analyst Task: Aggregate revenue by date/month and calculate running total.
*/
--Query
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(od.quantity * p.price) AS monthly_revenue
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    GROUP BY DATE_TRUNC('month', o.order_date)
),

cumulative_revenue AS (
    SELECT 
        month,
        monthly_revenue,
        SUM(monthly_revenue) OVER (ORDER BY month) AS cumulative_revenue
    FROM monthly_revenue
)

SELECT *
FROM cumulative_revenue
ORDER BY month;


13.Top 3 pizzas by Category(Revenue-Based)
Stakeholder(Product Head)

/*
"Witin each pizza category,which 3 pizzas bring the most revenue?
This will help us decide which pizzas to promote or expand."

Analyst Task: Partition by category,calculate revenue per pizza,rank top 3.
*/

--Query
WITH pizza_revenue AS (
    SELECT 
        pt.category,
        pt.name AS pizza_name,
        SUM(od.quantity * p.price) AS revenue
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
),

ranked_pizzas AS (
    SELECT 
        category,
        pizza_name,
        revenue,
        RANK() OVER (
            PARTITION BY category 
            ORDER BY revenue DESC
        ) AS rnk
    FROM pizza_revenue
)

SELECT 
    category,
    pizza_name,
    revenue
FROM ranked_pizzas
WHERE rnk <= 3
ORDER BY category, revenue DESC;


14. Top 10 Customers by spending
Stakeholder(Customers by Spending)

/*
"who are our top 10 customers based on total spend?
We want to reward them with loyality offers."
*/

--Query
WITH customer_spend AS (
    SELECT 
        c.custId,
        c.first_name || ' ' || c.last_name AS name,
        SUM(od.quantity * p.price) AS total_spend
    FROM customers c
    JOIN orders o 
        ON c.custId = o.custId
    JOIN order_details od
        ON o.order_id = od.order_id
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    GROUP BY c.custId, c.first_name, c.last_name
),

ranked_customers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_spend DESC) AS rnk
    FROM customer_spend
)

SELECT *
FROM ranked_customers
WHERE rnk <= 10;

15. Orders by weekday
Stakeholder(Marketing Team):

/*
"Which days of the week are busiest for orders?
Do customers order more on weekends?"
*/

--Query
SELECT 
    EXTRACT(DOW FROM order_date) AS day_num,
    TO_CHAR(order_date, 'Day') AS day_name,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY EXTRACT(DOW FROM order_date), TO_CHAR(order_date, 'Day')
ORDER BY day_num;


--> Weekend vs weekday Analysi
SELECT 
    CASE 
        WHEN EXTRACT(DOW FROM order_date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY day_type;

16.Average Order Size
Stakeholder (Supply Chain Manager)
/*
"What is the average number of pizzas per order?
This helps us in planning inventory and staffing"
*/

--Query
WITH order_totals AS (
    SELECT 
        o.order_id,
        SUM(od.quantity) AS pizzas_in_order
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    GROUP BY o.order_id
)

SELECT 
    ROUND(AVG(pizzas_in_order), 2) AS avg_pizzas_per_order
FROM order_totals;


17.Seasonal Trends
Stakeholder (Operations Manager)

/*
Do we see peak sales in certain months or holidays?
This will help us manage seasonal demand.
*/
--Query

--> Monthly Sales Trend
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    SUM(od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;

--> Peak Month Detection
SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    SUM(od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY month
ORDER BY revenue DESC;

-->Week vs Weekend Seasonality
SELECT 
    CASE 
        WHEN EXTRACT(DOW FROM order_date) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END AS day_type,
    SUM(od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY day_type;

18.Revenue by Pizza Size
Stakeholder (Dinance Head)

/*
"What is the revenue contribution of each pizza
Size(S,M,L,XL,XXL)"
*/
--Query
SELECT 
    p.size,
    SUM(od.quantity * p.price) AS total_revenue
FROM order_details od
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total_revenue DESC;


19.Customer Segmentation
Stakeholder (Customer Insights Team)

/*
"Do our high-value customers prefer premium pizzas or
regular pizzas? we want to personalize marketing."
*/
--Query
WITH customer_spend AS (
    SELECT 
        o.custId,
        SUM(od.quantity * p.price) AS total_spend
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    GROUP BY o.custId
),

high_value AS (
    SELECT custId
    FROM customer_spend
    ORDER BY total_spend DESC
    LIMIT 20
),

pizza_class AS (
    SELECT 
        pizza_id,
        price,
        CASE 
            WHEN price >= (SELECT AVG(price) FROM pizzas) 
            THEN 'Premium'
            ELSE 'Regular'
        END AS pizza_type
    FROM pizzas
)

SELECT 
    pc.pizza_type,
    SUM(od.quantity) AS total_qty
FROM order_details od
JOIN pizza_class pc
    ON od.pizza_id = pc.pizza_id
JOIN orders o
    ON od.order_id = o.order_id
JOIN high_value hv
    ON o.custId = hv.custId
GROUP BY pc.pizza_type;


20.Repeat Customer Rate
Stakeholder (CRM Head - Customer Relationship Manager)
/*
"We want to measure customer loyality.Can you calculate the percentage
of repeat customers (Customers who placed more than one order)
versus one-time buyer? This will help us design retention campaign."

Analyst Task: From the order table,count distinct customers,
			  Count how many customers have more than one order.
			  Calculate repeat rate = (repeat customers * total cuatomers) * 100
*/
--Query
WITH customer_orders AS (
    SELECT 
        o.custId,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    GROUP BY o.custId
),

customer_segments AS (
    SELECT 
        custId,
        CASE 
            WHEN total_orders > 1 THEN 'Repeat Customer'
            ELSE 'One-time Customer'
        END AS customer_type
    FROM customer_orders
)

SELECT 
    customer_type,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_share
FROM customer_segments
GROUP BY customer_type;










































