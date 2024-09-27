# Unilever data analysis using SQL
![Unilever logo](https://github.com/shristii589/unilvr_sql_project/blob/main/unilever2.png)
## Overview
This project focuses on analyzing the Unilever database, which consists of multiple tables designed to capture various aspects of customer and product interactions. The objective is to gain insights into sales performance, customer behavior, and pricing strategies through structured query language (SQL) analysis.
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

## 

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


