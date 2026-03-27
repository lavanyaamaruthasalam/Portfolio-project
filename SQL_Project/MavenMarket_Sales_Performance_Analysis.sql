/*
project: MavenMarket Sales & performance Analysis
objective: Top-line performance, Profitability analysis, Returns impact analysis, Customer and product insights, Data quality and integrity checks
key questions:
1. Total revenue and quantity sold per product, brand and customer
2. Top-performing products and customers
3. Total returns and return rate per product/brand
4. Profit analysis per product and brand
5. Identify High-Value and High-return products
6. Product performance comparison using Gross revenue, net revenue, profit margin
7. Customer segmentation insights based on purchase behavior
8. Data quality checks: missing or zero values, distinct counts

Notes:
- All calculations will use relevant joins between Transactions, Products, Customer and Returns tables
- Derived metrics like revenue, profit and return rates and ranking are calculated using CTEs and Window functions wherever necessary
- Time series analysis is not performed due to inconsistent date formatting in the source data

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
- Returns.product_id -> Products.product_id 

Data Limitations:
- Although a Regions table exists, it is not linked to Transactions or Returns via a foreign key.
- The Transactions and Returns tables do not contain a region_id or store_id columns, so region-level performance analysis could not be performed 
- Time series analysis is limited due to inconsistent date formatting
- All analysis are therefore limited to product, customer, brand  
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
Left join MavenMarket_Products p on r.product_id = p.product_id
where p.product_id is null;
select min(transaction_date)
from MavenMarket_Transactions;
select max(transaction_date)
from MavenMarket_Transactions;
with duplicate_transactions as(
select transaction_date, product_id, customer_id, store_id, quantity, row_number() over(partition by product_id, customer_id, transaction_date, store_id order by transaction_date) as rn
from MavenMarket_Transactions )
select *
from duplicate_transactions
where rn > 1;

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
-- Top5 products by total revenue(Ranked)
with product_revenue as(
select p.product_name, sum(t.quantity* p.product_retail_price) as Total_revenue
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name)
select *, rank() over(order by Total_revenue desc) as Revenue_Rank
from product_revenue;
-- Top5 products by quantity sold (Ranked)
with product_quantity as(
select p.product_name, sum(t.quantity) as Total_quanity
from MavenMarket_Transactions t
join MavenMarket_Products p ON t.product_id = p.product_id
group by p.product_name)
select *, rank() over(order by Total_quanity desc) as quantity_rank
from product_quantity;

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
-- Top 5 most returned products(Ranked)
with product_returns as(
select p.product_name, sum(r.quantity) as Products_Returned
from MavenMarket_Returns r
join MavenMarket_Products p ON r.product_id = p.product_id
group by p.product_name)
select *, dense_rank() over(order by Products_Returned desc) as return_rank
from product_returns;
-- Return rate per product(CTE)
with sales as(
select product_id, sum(quantity) as Total_quantity_sold
from MavenMarket_Transactions 
group by product_id), 
returns as (
select product_id, sum(quantity) as Total_quantity_returned
from MavenMarket_Returns 
group by  product_id ) 
select p.product_name, r.Total_quantity_returned, s.Total_quantity_sold, r.total_quantity_returned * 1.0 / s.Total_quantity_sold as return_rate
from returns r
join sales s on r.product_id = s.product_id
join MavenMarket_Products p on p.product_id = r.product_id ;
-- Return Contribution % per product(CTE)
with product_returns as(
select p.product_name, sum(r.quantity) as Total_returned
from MavenMarket_Returns r
join MavenMarket_Products p on r.product_id = p.product_id
group by p.product_name)
select *, Total_returned * 100.0 / sum(Total_returned) over () as contribution_percent
from product_returns;
-- High return Vs. Low sales Product (CTE)
with sales as(
select product_id, sum(quantity) as total_sold
from MavenMarket_Transactions 
group by product_id),
returns as (
select product_id, sum(quantity) as total_returned
from MavenMarket_Returns 
group by product_id)
select p.product_name, s.total_sold, r.total_returned, r.total_returned * 1.0 / s.total_sold as return_rate, 
RANK() over ( order by (r.total_returned * 1.0 / s.total_sold) desc ) as risk_rank 
from returns r
join sales s on r.product_id = s.product_id
join MavenMarket_Products p on p.product_id = r.product_id; 

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
-- Net revenue per product (CTE)
with sales as (
select t.product_id, sum(t.quantity * p.product_retail_price) as Gross_Revenue, sum(t.quantity * p.product_cost) as Total_Cost
from MavenMarket_Transactions t
join MavenMarket_Products p on t.product_id = p.product_id
group by t.product_id ), 
returns as (
select R.product_id, sum(quantity * p.product_retail_price) as Return_Value
from MavenMarket_Returns R
join MavenMarket_Products p on R.product_id = p.product_id
group by p.product_id)
select p.product_name, s.Gross_Revenue, r.Return_Value, (s.Gross_Revenue - r.Return_Value) as Net_Revenue
from sales s
join returns r on s.product_id = r.product_id
join MavenMarket_Products p on p.product_id = s.product_id;
-- Net Profit per product (CTE)
with sales as (
select t.product_id, sum(t.quantity * p.product_retail_price) as Gross_Revenue, sum(t.quantity * p.product_cost) as Total_Cost
From MavenMarket_Transactions t
join MavenMarket_Products p on t.product_id = p.product_id
group by t.product_id),
 returns as (
select r.product_id, sum(r.quantity * p.product_retail_price) as Return_Value
from MavenMarket_Returns r
join MavenMarket_Products p on r.product_id = p.product_id
group by r.product_id)
select p.product_name, s.Gross_Revenue,r.Return_Value, s.Total_Cost, (s.Gross_Revenue - r.Return_Value - s.Total_cost) as Profit
from Sales s
Join returns r on s.product_id = r.product_id
join MavenMarket_Products p on p.product_id = s.product_id;
-- Profit Margin per product (CTE)
with sales as (
select t.product_id, SUM(t.quantity * p.product_retail_price) as Gross_Revenue, sum(t.quantity * p.product_cost) as Total_Cost
from MavenMarket_Transactions t
join MavenMarket_Products p on t.product_id = p.product_id
group by t.product_id),
returns as (
select r.product_id, sum(r.quantity * p.product_retail_price) as Return_Value
from MavenMarket_Returns r
join MavenMarket_Products p on r.product_id = p.product_id
group by r.product_id)
select p.product_name, (s.Gross_Revenue - r.Return_Value - s.Total_Cost) *  100.0 / ( s.Gross_Revenue - r.Return_Value) as Profit_Margin
from sales s
join returns r on s.product_id = r.product_id
join MavenMarket_Products p on p.product_id = s.product_id;
-- Profit ranking per product (Ranked ,CTE)
with sales as(
select t.product_id, sum(t.quantity * p.product_retail_price) as Gross_Revenue, sum(t.quantity * p.product_cost) as Total_Cost
from MavenMarket_Transactions t
join MavenMarket_Products p on t.product_id = p.product_id
group by t.product_id),
returns as (
select r.product_id, sum(r.quantity * p.product_retail_price) as Return_Value
from MavenMarket_Returns r
join MavenMarket_Products p on r.product_id = p.product_id
group by r.product_id)
select p.product_name, (s.Gross_Revenue - r.Return_Value - s.Total_Cost) as Profit, Dense_rank() over(order by (s.Gross_Revenue - r.Return_Value - s.Total_Cost) desc) as Profit_Ranking
from sales s
join returns r on s.product_id = r.product_id
join MavenMarket_Products p on p.product_id = s.product_id;
-- Product Level performance summary (Gross Revenue, Profit, Profit Margin)(CTE)
with sales as (
select p.product_id, sum(t.quantity * p.product_retail_price) as Gross_Revenue, sum(t.quantity * p.product_cost) as Total_Cost
from MavenMarket_Transactions t
join MavenMarket_Products p on t.product_id = p.product_id
group by p.product_id),
returns as (
select r.product_id, sum(r.quantity * p.product_retail_price) as Return_Value
from MavenMarket_Returns r
join MavenMarket_Products p on r.product_id = p.product_id
group by r.product_id)
select p.product_name, s.Gross_Revenue, (s.Gross_Revenue - r.Return_Value - s.Total_Cost) as Profit, (s.Gross_Revenue - r.Return_Value - s.Total_Cost) * 100.0/ (s.Gross_Revenue - r.Return_Value) as Profit_Margin
from sales s
join returns r on s.product_id = r.product_id
join MavenMarket_Products p on p.product_id = s.product_id;
-- Problem statement insight table (Gross Revenue, Profit, Profit Margin, Return Rate)(CTE)
with sales as(
select t.product_id, sum(t.quantity * p.product_retail_price) as Gross_Revenue, sum(t.quantity * p.product_cost) as Total_Cost,
sum(t.quantity) as total_quantity_sold
from MavenMarket_Transactions t
join MavenMarket_Products p on p.product_id = t.product_id
group by t.product_id),
returns as(
select r.product_id, sum(r.quantity * p.product_retail_price) as Return_Value, sum(r.quantity) as total_quantity_returned
from MavenMarket_Returns r
join MavenMarket_Products p on r.product_id = p.product_id
group by r.product_id)
select p.product_name, s.Gross_Revenue, (s.Gross_Revenue - r.Return_Value - s.Total_Cost) as Profit, 
(s.Gross_Revenue - r.Return_Value - s.Total_Cost) * 100.0 / (s.Gross_Revenue - r.Return_Value) as Profit_Margin,
r.total_quantity_returned * 1.0 /s.total_quantity_sold * 100 as return_rate_percentage
from sales s
join returns r on s.product_id = r.product_id
join MavenMarket_Products p on p.product_id = r.product_id
order by return_rate desc;

-- ==========================
-- Customer Insights
-- ==========================
-- Analyze customer purchasing behavior to identify high-value, high-volume and repeat customers.
-- These insights help understand customer contribution to revenue
-- Support targeted business strategies.
-- High/Medium/Low value thresholds based on observed total sales range in dataset
-- Top 5 customer by sales
select concat(c.first_name," ",c.last_name) as Full_Name,sum(t.quantity * p.product_retail_price) as Total_Sales_Value
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
