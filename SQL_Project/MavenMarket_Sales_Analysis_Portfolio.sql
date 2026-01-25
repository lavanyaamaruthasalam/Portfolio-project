/*
project: MavenMarket Sales & performance Analysis
objective: Top-line performance, Profitability analysis, Region-wise performance, Returns impact analysis, Customer and product insights 
key questions:
1. Total revenue and quantity sold per product, brand and customer
2. Monthly and yearly sales trends
3. Top-performing products and customers
4. Total returns and return rate per product/brand
5. Profit analysis per product and brand
6. Identify High-Value and High-return products
7. Customer segmentation insights based on purchase behavior
8. Data quality checks: missing or zero values, distinct counts

Notes:
- All calculations will use relevant joins between Transactions, Products, Customer and Returns tables
- Derived metrics like revenue, profit and return rates will be calculated
- Time series analysis will use available transaction_date column

Dataset Overview:
- This analysis uses MavenMarket Transactional sales, product, customer and returns data

Tables Used:
- MavenMarket_Transactions
- MavenMarket_Products
- MavenMarket_Customers
- MavenMarket_Returns

Table Relationships:
- Transactions.product_id -> Products.product_id
- Transactions.customer_id -> Customers.customer_id
- Retruns.product_id -> Products.product_id 

Data Limitations:
- Although a Regions table exists, it is not linked to Transactions or Returns via a foriegn key.
- The Transactions and Returns tables do not contain a region_id or store_id column.
- Due to the absence of a valid relationship, region-level performance analysis could not be performed.
- All analysis are therefore limited to product, customer, brand and time-based dimensions. 
*/

-- ==========================
-- Data Sanity Checks
-- ==========================
-- Validate row counts, nulls and data consistency
select count(*) as Transactions_Row_Count
from MavenMarket_Transactions;
select count(*) as Products_Row_Count
from MavenMarket_Products;
select count(*) as Customers_Row_Count
from MavenMarket_Customers;
select count(*) as Returns_Row_Count
from MavenMarket_Returns;
select *
from MavenMarket_Transactions
where quantity <= 0 or quantity is null;
select *
from MavenMarket_Products
where product_retail_price <= 0 or product_retail_price is null;
select * 
from MavenMarket_Returns
where quantity <= 0 or quantity is null;
select t.product_id
from MavenMarket_Transactions t
left join MavenMarket_Products p on t.product_id = p.product_id
where p.product_id is null;
select t.customer_id
from MavenMarket_Transactions t
left join MavenMarket_Customers c ON t.customer_id = c.customer_id
where c.customer_id is null;
select r.product_id
from MavenMarket_Returns r 
join MavenMarket_Products p on r.product_id = p.product_id
where p.product_id is null;
select min(transaction_date)
from MavenMarket_Transactions;
select max(transaction_date)
from MavenMarket_Transactions;

-- ==========================
-- Core sales & revenue Analysis
-- ==========================
-- Analyze Total quantity sold and total revenue at product, brand and customer levels.
-- These metrics help identify top-performing products, brands and customers,
-- and form the foundation for deeper performance and profitability analysis.
-- total revenue and quantity sold per product
select p.product_name, sum(t.quantity) as Total_Quantity_Sold, sum(t.quantity * p.product_retail_price) as Total_Revenue
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name;
-- Total revenue and quantity per brand 
select p.product_brand, sum(t.quantity) as Total_Quantity_Sold, sum(t.quantity * p.product_retail_price) as Total_Revenue
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_brand;
-- Total revenue and quantity per customer 
select concat(c.first_name," ",c.last_name) as Full_Name,  sum(t.quantity) as Total_Quantity_Sold, sum(t.quantity * p.product_retail_price) as Total_Revenue
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
join MavenMarket_Customers c ON t.customer_id = c.customer_id
group by Full_Name;
-- Top5 products by quantity sold
select p.product_name, sum(t.quantity) as Total_Quantity_Sold
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name
order by Total_Quantity_Sold desc
limit 5;
-- Top5 products by total revenue
select p.product_name, sum(t.quantity * p.product_retail_price) as Total_Revenue
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name
order by Total_Revenue desc
limit 5;

-- ==========================
-- Returns Analysis
-- ==========================
-- Analyze total returned quantities and return rates at product and brand levels
-- These metrics help identify high-return products and assess the impact of returns
-- on overall revenue and profitability 
-- Total returns by products
select p.product_name, sum(r.quantity) as Total_Product_Quantity_Returned 
from MavenMarket_Returns r
join MavenMarket_Products p ON r.product_id = p.product_id
group by p.product_name;
-- Total returns by brand
select p.product_brand, sum(r.quantity) as Total_Brand_Quantity_Returned
from MavenMarket_Returns r
join MavenMarket_Products p ON r.product_id = p.product_id
group by p.product_brand;
-- Top 5 most returned products
select p.product_name, sum(r.quantity) as Total_Products_Returned
from MavenMarket_Returns r
join MavenMarket_Products p ON r.product_id = p.product_id
group by p.product_name
order by Total_Products_Returned desc
limit 5;
-- Return rate per product
select p.product_name, sum(r.quantity) * 1.0 / sum(t.quantity) as Return_Rate_per_product
from MavenMarket_Returns r
join MavenMarket_Transactions t ON t.product_id = r.product_id
join Mavenmarket_Products p ON r.product_id = p.product_id
group by p.product_name;

-- ==========================
-- Profitability Impact Analysis
-- ==========================
-- Evaluate the impact of product returns on sales revenue
-- by comparing gross revenue, return value and net revenue.
-- This analysis highlights products and brands where returns significantly reduce overall profitability
-- Gross revenue per product 
select p.product_name, sum(t.quantity * p.product_retail_price) as Gross_Revenue
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_id;
-- Return value per product
select p.product_name, sum(r.quantity * p.product_retail_price) as Return_Value
from MavenMarket_Returns r
join MavenMarket_Products p ON r.product_id = p.product_id
group by p.product_name;
-- Net revenue per product after returns
select p.product_name, ( sum(t.quantity * p.product_retail_price)-sum(r.quantity * p.product_retail_price )) as Net_Revenue
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name;
-- Gross Profit per brand
select p.product_brand, ( sum(t.quantity * p.product_retail_price) -sum(r.quantity * p.product_retail_price) -sum(t.quantity * p.product_cost )) As Gross_Brand_Profit
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_brand;
-- Profit Margin% per brand
select p.product_brand, (sum(t.quantity * p.product_retail_price)- sum(t.quantity * p.product_cost) - sum(r.quantity*p.product_retail_price) ) / ( sum(t.quantity * p.product_retail_price) - sum(r.quantity * p.product_retail_price) )as Profit_Margin
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_brand;
-- Top 5 Brands with high return rate
select p.product_brand, sum(r.quantity) * 1.0 / sum(t.quantity) as Brand_Return_rate
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_brand
order by Brand_Return_Rate desc
limit 5;
-- Top 5 products with Negative profit margin
select p.product_name, ( ( sum(t.quantity * p.product_retail_price)-sum(r.quantity * p.product_retail_price )) -sum(t.quantity * p.product_cost ) / ( sum(t.quantity * p.product_retail_price)-sum(r.quantity * p.product_retail_price )) ) as Profit_Margin
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name
order by Profit_Margin desc
limit 5;
-- Brand level Return Impact on Gross Revenue Vs Net Revenue
select p.product_brand, sum(t.quantity * p.product_retail_price) as Gross_Revenue , sum(r.quantity * p.product_retail_price) as Return_Value, 
(sum(t.quantity * p.product_retail_price) - sum(r.quantity * p.product_retail_price) ) as Net_Revenue, (sum(r.quantity * p.product_retail_price)/sum(t.quantity * p.product_retail_price)) as Return_Impact
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_brand;
-- Brand level Return Impact on Gross Profit vs Net Profit
select p.product_brand, ( sum(t.quantity * p.product_retail_price) -sum(r.quantity * p.product_retail_price) -sum(t.quantity * p.product_cost )) as Gross_Profit, sum(r.quantity * p.product_retail_price) as Return_Value, ( ( sum(t.quantity * p.product_retail_price)-sum(r.quantity * p.product_retail_price )) - sum(t.quantity *p.product_cost) ) as Net_Profit,
 (sum(r.quantity * p.product_retail_price))/ ( ( sum(t.quantity * p.product_retail_price)-sum(r.quantity * p.product_retail_price )) - sum(t.quantity * p.product_cost ) ) as Return_Impact
from MavenMarket_Transactions t
join MavenMarket_Returns r ON t.product_id = r.product_id
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_brand;

-- ==========================
-- Customer Insights
-- ==========================
-- Analyze customer purchasing behavior to identify high-value, high-volume and repeat customers.
-- These insights help understand customer contribution to revenue
-- Support targeted business strategies.
-- High/Medium/Low value thresholds based on observed total sales range in dataset
-- Top 5 customer by sales
select concat(c.first_name," ",c.last_name) as Full_Name, sum(t.quantity * p.product_retail_price) as Total_Sales_Value
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
join MavenMarket_Customers c ON t.customer_id = c.customer_id
group by concat(c.first_name," ",c.last_name)
order by Total_Sales_Value desc
limit 5;
-- Top 5 customers on purchase quantity
select concat(c.first_name," ",c.last_name) as Full_Name, sum(t.quantity) as Total_Purchase_Quantity
from MavenMarket_Transactions t
join MavenMarket_Customers c on t.customer_id = c.customer_id
group by concat(c.first_name," ",c.last_name)
order by Total_Purchase_Quantity desc
limit 5;
-- Top 5 frequent buyers
select concat(c.first_name," ",c.last_name) as Full_Name, count(transaction_date) as Number_of_Transactions
from MavenMarket_Transactions t
join MavenMarket_Customers c ON t.customer_id  = c.customer_id
group by concat(c.first_name," ",c.last_name)
order by Number_of_Transactions desc
limit 5;
-- Average order value per customer
select concat(c.first_name," ",c.last_name) as Full_Name, sum(t.quantity * p.product_retail_price) / count(distinct transaction_date)as Average_Order_Value
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
join MavenMarket_Customers c ON t.customer_id = c.customer_id
group by concat(c.first_name," ",c.last_name)
order by Average_Order_Value desc;
-- Customer segmentation by Total Sales
select concat(c.first_name," ",c.last_name) as Full_Name, sum(t.quantity * p.product_retail_price) as Total_Sales_Value,
case 
	when sum(t.quantity * p.product_retail_price) >=1500 then 'High Value Customer'
	when sum(t.quantity * p.product_retail_price) >=500 then 'Medium Value Customer'
	else 'Low Value Customer'
end as Customer_Category
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
join MavenMarket_Customers c ON t.customer_id = c.customer_id
group by concat(c.first_name," ",c.last_name)
order by Total_Sales_Value desc;

-- ==========================
-- Final Business Takeaways
-- ==========================
-- Top-performing products and brands drive the majority of revenue,highlighting key areas for marketing and inventory focus.
-- High-return products and brands significantly reduce net revenue and profit margins; corrective actions may be needed.
-- some products or brands show negative profit after returns,directly lowering overall profitability.
-- A small group of high-value customers contributes much more revenue than others, highlighting the importance of retaining them.
-- Frequent buyers and customers with high average order value present opportunities for personalized promotions and offers.
-- Customer segmentation provides actionable marketing and resource allocation.



