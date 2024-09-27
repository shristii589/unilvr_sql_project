# Unilever data analysis using SQL
![Unilever logo](https://github.com/shristii589/unilvr_sql_project/blob/main/unilever2.png)
## Overview
This project focuses on analyzing the Unilever database, which consists of multiple tables designed to capture various aspects of customer and product interactions. The objective of this SQL project is to gain insights into sales performance and customer behavior using a dataset modeled after Unilever's business structure. The project involves analyzing sales data to identify trends, understand customer segments, and evaluate customer, market and product performances.

## Objectives
The primary objectives of this project are:

1. To analyze customer purchasing patterns and identify key segments.

2. To evaluate product performance across different regions and categories.

3. To assess the impact of pricing strategies, including discounts, on overall sales.

4. To generate insights that can support decision-making for marketing and sales strategies.
## Disclaimer
This project uses a "fictional dataset" based on the structure of Unilever. The data is completely synthetic and used solely for educational purposes. None of the information represents real company data or business operations.

## Dataset
Dataset link 

## Data structure
The Unilever database is composed of the following tables:
1. dim_customer: This dimension table contains detailed information about customers, including unique identifiers, names, markets, regions, and subzones.
 
2. dim_product: This dimension table provides information about products, including identifiers, segments, divisions, categories, and product names.
 
3. fact_sales: This fact table records sales transactions, linking customer and product data. It includes the quantity sold, sale date, and year, facilitating comprehensive sales analysis.
 
4. fact_gross_price: This table captures the gross price per product for each year, enabling price trend analysis over time.
 
5. fact_pre_invoice_deductions: This table records pre-invoice discounts applied to transactions, detailing discount percentages and other deductions, which helps assess pricing strategies.
 
6. fact_post_invoice_deductions: This table records post-invoice discount percentages, providing insights into the effectiveness of discounts and their impact on sales.

## Business problems and solutions

### Q1. Find the top performing customer in terms of quantity sold in fiscal year 2021.

```sql
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
```
**Objective-** To understand which customers drive the highest volume of product distribution, enabling company to strengthen partnerships and prioritizing customer relationships that significantly impact sales performance.

### Q2. Create a function to get the fiscal year's quarter.

```sql
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
```

### Q3.  Generate gross sales report for globalmart ltd , India for fiscal year 2021.

```sql
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
```

### Q4. Create a stored procedure to get customized report of gross sales for the given customer, market and fiscal year.

```sql
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
```

### Q5. Analyze monthly sales trends for product lakme sun expert spf50+.
Step 1 - To get the product code for "lakme sun expert spf 50

```sql
select *
from dim_product
where product="lakme sun expert spf50+"
```

Step 2 - To get the monthly sales for the product lakme sun expert spf50+

```sql
SELECT 
    s.date, SUM(s.sold_quantity) AS total_sales
FROM
    fact_sales s
        JOIN
    dim_customer c
WHERE
    product_code = 'A3920150303'
GROUP BY s.date
ORDER BY s.date;
```

### Q6. Find are the products having higher than average sales for fiscal year 2021 ?

```sql
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
```

## Q7. Create a report to show gross sales performance over region for quarter 2 of fiscal year 2020.

```sql
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
GROUP BY c.region;
```

### Q8. Create a report showcasing the percent share of customer over gross sales for fiscal year 2020.

```sql
with cte1 as (
select c.customer,
       sum(s.sold_quantity*g.gross_price)/1000000 as gross_sales_mln
from fact_sales s
join dim_customer c
on s.customer_code = c.customer_code
join fact_gross_price g
on s.product_code = g.product_code and
   s.fiscal_year = g.fiscal_year
where s.fiscal_year = 2021
group by c.customer)
select *,
        gross_sales_mln*100/sum(gross_sales_mln) over () as pct
from cte1
order by gross_sales_mln desc;
```

### Q9. Create a report of top 3 products in each division by their sales quantity for fiscal year 2021.

```sql
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
```

### Q10. Create a report of top 5 products by net sales for fiscal year 2021 with the help of views

Step 1 - Create a view named sales_pre using query mentioned below 

```sql
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
```
Step 2 - Create a view named netinvsales2 using  query mentioned below

```sql
SELECT 
    s.date,
    s.fiscal_year,
    s.customer_code,
    s.product_code,
    s.customer,
    s.market,
    s.product,
    s.sold_quantity,
    s.gross_price_per_item,
    s.gross_sales,
    s.pre_invoice_discount_pct,
    s.gross_sales - s.gross_sales * s.pre_invoice_discount_pct AS net_invoice_sales,
    po.discounts_pct + po.other_deductions_pct AS total_post_disc
FROM
    sales_pre s
        JOIN
    fact_post_invoice_deductions po ON s.customer_code = po.customer_code
        AND s.product_code = po.product_code
        AND s.date = po.date;
  ```

Step 3 - Create a view named net_sales2 using  query mentioned below 

```sql
SELECT 
    *,
    net_invoice_sales - net_invoice_sales * total_post_disc AS net_sales
FROM
    netinvsales2;
```

Step 4 - Get top 5 products by net_sales for fiscal year 2021

```sql
SELECT 
    product, SUM(net_sales) AS _netsales
FROM
    net_sales2
WHERE
    fiscal_year = 2021
GROUP BY product
ORDER BY _netsales DESC
LIMIT 5;
```


## Conclusion

This project aims to provide a comprehensive analysis of the Unilever database, uncovering valuable insights that can enhance business strategies and drive growth. By leveraging SQL for data analysis, the project will contribute to a better understanding of customer and product dynamics within the Unilever brand.
