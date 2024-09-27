-- Q1. Find the top performing customer in terms of quantity sold in fiscal year 2021. 
SELECT 
    c.customer, SUM(s.sold_quantity) AS total_qty_sold
FROM
    fact_sales s
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
WHERE
    s.fiscal_year = 2021
GROUP BY c.customer
ORDER BY total_qty_sold DESC
LIMIT 1;

-- Q2. Create a function to get the fiscal year's quarter.
CREATE DEFINER=`root`@`localhost` FUNCTION `fiscal_year_qtr` (date date) 
RETURNS char(2) CHARSET utf8mb4
DETERMINISTIC
 BEGIN
       declare m tinyint;
       declare qtr char(5);
	   set m = month(date);
       case 
          when m in (9,10,11) then set qtr = "Q1";
          when m in (12,1,2) then set qtr = "Q2";
          when m in (3,4,5) then set qtr = "Q3";
          else set qtr = "Q4";
          end case;

 RETURN qtr;
 END;

-- Q3. generate gross_sales report for globalmart ltd , India for fiscal_year 2021
SELECT 
    s.date,
    s.fiscal_year,
    s.customer_code,
    s.product_code,
    c.customer,
    c.market,
    p.product,
    s.sold_quantity,
    g.gross_price,
    g.gross_price * s.sold_quantity AS gross_sales
FROM
    fact_sales s
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
        JOIN
    dim_product p ON s.product_code = p.product_code
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
WHERE
    s.fiscal_year = 2021
        AND s.customer_code IN (70002017 , 90002011)
LIMIT 15000000;

-- Q4. Create a stored procedure to get customized report of gross sales for the given customer, market and fiscal_year.
CREATE DEFINER=`root`@`localhost` PROCEDURE `gross_sales_report`(
in in_customer_code text,
 in in_fiscal_year int)
BEGIN
select
 s.date,s.fiscal_year,s.customer_code,s.product_code,
c.customer,c.market,p.product,s.sold_quantity,g.gross_price,
g.gross_price*s.sold_quantity as gross_sales 
from fact_sales s
join dim_customer c
on s.customer_code = c.customer_code
join dim_product p
on s.product_code = p.product_code
join fact_gross_price g
on s.product_code = g.product_code and s.fiscal_year=g.fiscal_year
where find_in_set(s.customer_code,in_customer_code)>0
and s.fiscal_year = in_fiscal_year
  limit 15000000;
END;

-- Q5. analyze monthly sales trends for product
SELECT 
    s.date, SUM(s.sold_quantity) AS total_sales
FROM
    fact_sales s
        JOIN
    dim_customer c
WHERE
    product_code = 'A0118150101'
GROUP BY s.date
ORDER BY s.date;

-- Q6. What are the products having higher than average sales for fiscal_year 2021 ?
SELECT p.product, SUM(s.sold_quantity) AS total_quantity_sold
FROM fact_sales s
JOIN dim_product p ON s.product_code = p.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.product
HAVING SUM(s.sold_quantity) > (
    SELECT AVG(total_sales)
    FROM (
        SELECT SUM(fs.sold_quantity) AS total_sales
        FROM fact_sales fs
        WHERE fs.fiscal_year = 2021
        GROUP BY fs.product_code
    ) AS avg_sales
);


-- Q7. Gross sales performance over region for quarter 2 of fiscal year 2020.

SELECT 
    c.region,
    SUM(s.sold_quantity * g.gross_price) / 1000000 AS gross_sales_mln
FROM
    fact_sales s
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
WHERE
    FISCAL_YEAR_QTR(s.date) = 'Q2'
        AND s.fiscal_year = 2020
GROUP BY c.region

-- Q8. Create a report showcasing the percent share of customer by sales quantity for fiscal year 2020.

with cte1 as (select c.customer,sum(s.sold_quantity*g.gross_price)/1000000 as gross_sales_mln
from fact_sales s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price g
on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year
where s.fiscal_year = 2021 group by c.customer)
select *,gross_sales_mln*100/sum(gross_sales_mln) over () as pct from cte1 order by gross_sales_mln desc;

-- Q9. Create a report of top 3 products in each division by their sales quantity for fiscal year 2021.

with cte1 as (
select p.division,p.product,sum(sold_quantity) as total_qty
from fact_sales s
join dim_product p 
on s.product_code = p.product_code
where s.fiscal_year = 2021 
group by p.division,p.product),
cte2 as (
select *,
 dense_rank () over (partition by division order by total_qty desc)
 as drank from cte1 )
select * from cte2 where drank<=3;


-- Q10. Create a report of top 5 products by net sales for fiscal_year 2021 with the help of cte's or views

select s.date,
s.fiscal_year,
s.customer_code,
s.product_code,
c.customer,
c.market,
p.product,
s.sold_quantity,
g.gross_price as gross_price_per_item,
g.gross_price*s.sold_quantity as gross_sales,
pre.pre_invoice_discount_pct
from fact_sales s
join dim_customer c
on s.customer_code = c.customer_code
join dim_product p
on s.product_code = p.product_code
join fact_gross_price g
on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year
join fact_pre_invoice_deductions pre
on s.customer_code = pre.customer_code and s.fiscal_year = pre.fiscal_year
limit 1500000;


select s.date,s.fiscal_year,s.customer_code,s.product_code,s.customer,s.market,s.product
,s.sold_quantity,s.gross_price_per_item,s.gross_sales,s.pre_invoice_discount_pct,
s.gross_sales-s.gross_sales*s.pre_invoice_discount_pct as net_invoice_sales ,
po.discounts_pct+po.other_deductions_pct as total_post_disc
from sales_pre s
join fact_post_invoice_deductions po
on s.customer_code=po.customer_code and s.product_code=po.product_code and s.date=po.date;
  
-- save above query as a view named netinvsales2
  
select *, net_invoice_sales-net_invoice_sales*total_post_disc as net_sales from netinvsales2;

-- save above query as net_sales2

select * from net_sales2 limit 1500000;

select product,sum(net_sales) as _netsales from net_sales2 
 where fiscal_year=2021 group by product order by _netsales desc limit 5  ;