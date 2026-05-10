/*
Project: Revenue Concentration & Pareto Analysis
Objective: Analyze revenue concentration across brands and products to evaluate whether the business follows the Pareto(80/20) principle or demonstrates diversified revenue distribution.

Key Questions:
1.Which brands contribute the highest revenue?
2.What percentage of total revenue comes from top-performing brands?
3.Does the business follow the classic 80/20 Pareto rule?
4.How concentrated or diversified is brand revenue distribution?
5.Which products contribute most within the top-performing brand?
6.How does cumulative revenue contribution behave across rankings?
7.Do product-level contribution patterns also show diversification?

Notes:
- Revenue calculations performed using transaction quantity and product retail price
- CTEs and Window functions used for ranking and cumulative contribution analysis
- Pareto analysis performed at both brand and product level
- Product-level drill-down performed on the top revenue-generating brand
- Power BI used for dashboard visualization and DAX-based contribution analysis

Dataset OverView:
- This analysis uses MavenMarket retail transactional data, containing sales, product and customer information

Tables used:
- MavenMarket_Transactions
- MavenMarket_Products
- MavenMarket_Customers

Table relationships:
- Transactions.product_id -> products.product_id
- Transactions.customer_id -> Customers.customer_id

Data Limitations:
- Region/store-level concentration analysis was not performed due to unavailable relationships
- Revenue analysis is limited to available transactional data
- Product contribution percentages depend on selected brand context 
*/

-- =========================
-- Data sanity checks
-- =========================
-- Validates row counts, null values, duplicates and product relationships
select count(*) as Transactions_row_count
from Transactions;
select count(*) as products_row_count
from Products;
select count(*) as customers_row_count
from Customers;
select *
from Transactions
where quantity <= 0 or quantity is null;
select *
from Products
where product_retail_price <= 0 or product_retail_price is null;
select *
from Customers
where customer_id is null or first_name is null or last_name is null;
select t.product_id
from Transactions t
left join Products p on t.product_id = p.product_id
where p.product_id is null;
select t.customer_id
from Transactions t
left join Customers c on t.customer_id = c.customer_id
where c.customer_id is null;

-- =========================
-- Business Revenue Analysis
-- =========================
-- Calculate revenue, quantity sold & profit
-- Overall Revenue
select  sum(t.quantity * p.product_retail_price) as total_revenue
from Transactions T
join products p on t.product_id = p.product_id;
-- Quantity Sold
select sum(t.quantity) as total_quantity
from Transactions t;
-- Overall Profit
select sum((p.product_retail_price - p.product_cost) * t.quantity) as total_profit
from Transactions t
join Products p on t.product_id = p.product_id;

-- =========================
-- Brand Revenue Analysis
-- =========================
-- Analyze total quantity sold and revenue at brand level
-- and ranking brands by revenue, identifying top performing 
-- These metrics helps in diversified revenue distribution across brands
-- Brand Ranking by Revenue
select p.product_brand, sum(t.quantity * p.product_retail_price) as total_revenue, 
rank() over(order by sum(t.quantity * p.product_retail_price) desc) as brand_rank
from Transactions t
join Products p on t.product_id = p.product_id 
group by p.product_brand;
-- Top performing Brands
select p.product_brand, sum(t.quantity * p.product_retail_price) as total_revenue
from Transactions t
join Products p on t.product_id = p.product_id
group by p.product_brand
order by total_revenue desc
limit 10;
-- Brand Total Quantity & Revenue
select p.product_brand, sum(t.quantity) as total_quantity, sum(t.quantity * p.product_retail_price) as total_revenue 
from Transactions t
join Products p on t.product_id = p.product_id
group by p.product_brand
order by total_revenue desc;
-- Brand Revenue Contribution%
with brand_revenue as (
select p.product_brand, sum(t.quantity * p.product_retail_price) as revenue
from Transactions t
join Products p on t.product_id = p.product_id
group by p.product_brand),
total as(
select sum(revenue) as total_revenue
from brand_revenue )
select b.product_brand, b.revenue, round(( b.revenue * 100.0/ t.total_revenue), 2) as revenue_pct
from brand_revenue b
cross join total t
order by revenue_pct desc;

-- =========================
-- Pareto/Cumulative Revenue analysis
-- =========================
-- Analyze top brands contribution and cumulative brand & product contribution
-- These metrics shows lesser concentrated revenue among brands & products
-- indicating weak 80/20 principle
-- Product Cumulative Contribution
with product_revenue as(
select p.product_name, sum(t.quantity * p.product_retail_price) as revenue
from Transactions t
join Products p on t.product_id = p.product_id
group by p.product_name ),
ranked as (
select product_name, revenue, sum(revenue) over (order by revenue desc) as cumulative_revenue, sum(revenue) over() as total_revenue
from product_revenue)
select product_name, revenue, round((cumulative_revenue * 100.0 / total_revenue), 2) as cumulative_pct
from ranked
order by revenue desc;
-- Brand Cumulative Contribution
with brand_revenue as (
SELECT  p.product_brand, sum(t.quantity * p.product_retail_price) as revenue
from Transactions t
join Products p on t.product_id = p.product_id
group by product_brand
order by revenue desc),
ranked as (
select product_brand, revenue, sum(revenue) over(order by revenue desc) as cumulative_revenue,
sum(revenue) over () as total_revenue
from brand_revenue)
select product_brand, revenue, round(( cumulative_revenue * 100.0/ total_revenue), 2) as cumulative_pct
from ranked 
order by revenue desc;
-- Top 10 Brand Contribution
with brand_revenue as (
select p.product_brand, sum(T.quantity * p.product_retail_price) as revenue
from Transactions T
join Products p on T.product_id = p.product_id
group by p.product_brand),
top_10 as(
select  product_brand, revenue
from brand_revenue
order by revenue desc 
limit 10)
select round(sum(revenue),2) as top_10_revenue, round(sum(revenue) * 100.0/ (select sum(revenue) from brand_revenue),2) as top_10_contribution
from top_10;

-- =========================
-- Product level Analysis
-- ========================= 
-- Analyze product revenue contribution and top products
-- Product drill-down analysis shows distributed contribution 
-- Wthin Hermanos, the highest revenue-generating product
-- Product Revenue Contribution
with product_revenue as (
select p.product_name, sum(t.quantity * p.product_retail_price) as revenue
from Transactions t
join Products p on t.product_id = p.product_id
group by p.product_name),
total as(
select sum(revenue) as total_revenue
from product_revenue)
select pr.product_name, pr.revenue, round((pr.revenue*100.0/t.total_revenue), 2) as revenue_pct
from product_revenue pr
cross join total t
order by revenue_pct desc;
-- Product Ranking Top 10 brand
select p.product_name, sum(t.quantity * p.product_retail_price) as total_revenue,
rank() over (order by sum(t.quantity * p.product_retail_price) desc ) as product_rank
from Transactions t
join Products p on t.product_id = p.product_id 
where p.product_brand = 'Hermanos'
group by p.product_name;
-- top Products Within Hermanos
select p.product_name, SUM(t.quantity * p.product_retail_price) as total_revenue
from Transactions t
join Products p on t.product_id = p.product_id
where product_brand ='Hermanos'
group by p.product_name 
order by total_revenue desc
limit 10;

-- ========================= 
-- Final Business Takeaways
-- ========================= 
-- Revenue distribution was relatively diversified across brands, rather than heavily concentrated among a few dominant players
-- Top 10 brands contributed approximately 26% of total revenue, indicating weak adherence to the traditional 80/20 Pareto principle
-- The highest revenue-generating brand [hermanos] contributed only around 3.2% of overall revenue
-- Product-level drill-down analysis also showed distributed contribution patterns within the top-performing brand
-- The business demonstrates a long-tail revenue structure reducing dependency risk on individual brands


