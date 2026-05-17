/*
Poject: Customer Segmentation and RFM Analysis
Objective: Build a complete customer analytics framework to segment customers based on Recency, Frequency and Monetary(RFM) behavior and identify high-value customers, churn risks, retention opportunities and geographic performance patterns.

Key Questions:
1.Which customer segments contribute the most revenue?
2.Which customers are newly acquired and require retention?
3.Which customers are at risk of churning?
4.Which Lost customers are worth winning back?
5.How can the business refine segmentation logic to better understand customer behavior?
6.Which store formats and regions generate the strongest performance?

Notes:
- Raw transactional data was validated for null values, duplicates and missing relationships
- Duplicate transactions were removed to create a clean transaction table
- An Analytical Base Table(ABT) was built by joining transactions, customers, products, stores and regions
- Customer Metrics were calculated to measure revenue, profit, recency, frequency, lifespan, diversity and tenure
- RFM scores were assigned using NTILE(5) windows funtions
- Customers were classified into business-friendly segments using CASE logic

Dataset Overview:
This analysis uses Maven Market retail data containing transaction history, customer profiles, product details, store information and regional hierarchy

Tables used;
- MavenMarket_Transactions
- MavenMarket_Customer
- MavenMarket_Product
- MavenMarket_Store
- MavenMarket_Region

Derived Tables:
- Transactions_New
- Analytical_Base_table
- Customer_Metrics
- Customer_RFM
- Customer_Segments

Table Relationship:
- Transcations.customer_id -> Customer.customer_id
- Transaction.product_id -> Porducts.product_id
- Transactions.store_id -> Store.store_id
- Store.region_id -> Region.region_id

Data limitations:
- Customer behavior is based only on available historical transactions
- Segmentation rules are business-defined and may require further refinement
- The "Others" segemnt contains customers who not match RFM threshold
- Profit calculations are based on retail price and product cost only
*/

-- ===========================
-- Data Sanity Check
-- ===========================
-- Validate row counts across all source tables
-- Check for null, duplicates values and missing prices
select count(*) as customer_row
from Customer;
select count(*) as product_row
from Product;
select count(*) as region_row
from Region;
select count(*) as store_row
from Store;
select count(*) as trsanactions_row
from Transactions;
select *
from Transactions
where quantity <= 0 or quantity is null;
select *
from Product
where product_retail_price <= 0 or product_retail_price is null;
select *
from Customer
where customer_id is null or first_name is null or last_name is null;
select *
from Store
where store_id <= 0 or store_id is null;
select *
from Region
where region_id <= 0 or region_id is null;
select *
from Transactions t
left join Customer c on t.customer_id = c.Customer_id
where c.customer_id is null;
select * 
from Transactions t
left join Product p on t.product_id = p.product_id
where p.product_id is null;
select *
from Transactions t
left join Store s on t.store_id = s.store_id
where s.store_id is null;
select *
from Store s
left join Region r on s.region_id = r.region_id 
where r.region_id is null;

-- ===========================
-- Duplicate detection
-- ===========================
-- Create a new transactions table
--Detact duplicate transactions and duplicate primary keys
select Transaction_date, stock_date, customer_id, product_id,store_id,quantity, count(*) as duplicate_count
from Transactions 
group by  Transaction_date, stock_date, customer_id, product_id,store_id, quantity 
having count (*) > 1;
create table Transactions_new as
select distinct transaction_date, stock_date, product_id, customer_id, store_id, quantity
from Transactions;
select Transaction_date, stock_date, customer_id, product_id,store_id,quantity, count(*) as duplicate_count
from Transactions_new 
group by  Transaction_date, stock_date, customer_id, product_id,store_id, quantity 
having count (*) > 1;
select customer_id , count(*) as duplicate_count
from Customer
group by customer_id
having count(*) > 1;
select product_id , count(*) as duplicate_count
from Product
group by product_id
having count(*) >1;
select store_id, count(*) as duplicate_count
from Store
group by store_id
having count(*) >1;
select region_id, count(*) as duplicate_count
from Region
group by region_id
having count(*) > 1;
select count(*) as original_rows
from Transactions;
select count(*) as cleaned_row
from Transactions_new;

-- ===========================
-- Analytical Base Table(ABT)
-- ===========================
-- Create analytical Base Table 
-- This combines Transactions + customer + product + region + store
-- and calculates Revenue & Profit
drop table if exists Analytical_Base_table;
create table Analytical_Base_table as 
select 
t.transaction_date,
t.stock_date,
t.product_id,
t.customer_id,
t.store_id,
t.quantity,
c.customer_id,
c.customer_acct_num,
c.customer_name,
c.first_name,
c.last_name,
c.customer_address,
c.customer_city,
c.customer_state_province,
c.customer_postal_code,
c.customer_country,
c.birthdate,
c.marital_status,
c.yearly_income,
c.gender,
c.total_children,
c.num_children_at_home,
c.education,
c.acct_open_date,
c.member_card,
c.occupation,
c.homeowner,
p.product_id,
p.product_brand,
p.product_name,
p.product_sku,
p.product_retail_price,
p.product_cost,
p.product_weight,
p.recyclable,
p.low_fat,
s.store_id,
s.region_id,
s.store_type,
s.store_name,
s.store_state,
s.store_city,
s.store_state2,
s.store_country,
s.store_phone,
s.first_opened_date,
s.last_remodel_date,
s.total_sqft,
s.grocery_sqft,
r.region_id,
r.sales_district,
r.sales_region,
(t.quantity * p.product_retail_price) as revenue,
(t.quantity * (p.product_retail_price - p.product_cost)) as profit
from Transactions_new t
left join Customer c on t.customer_id = c.customer_id
left join product p on t.product_id = p.product_id
left join Store s on t.store_id = s.store_id
left join Region r on s.region_id = r.region_id;

-- ===========================
-- Customer Metrics
-- ===========================
-- Calculate customer-level KPI
-- Revenue, Profit, avrage order value, orders, quanity,
-- purchase dates, lifespan, recency, frequency, diversity metrics and customer tenure
drop table if exists Customer_Metrics;
create table Customer_Metrics as
select customer_id, customer_name, 
-- revenue metrics
sum(revenue) as total_revenue,
sum(profit) as total_profit,
count(distinct transaction_date) as total_orders,
sum(quantity) as total_quantity_purchased,
sum(revenue) * 1.0 / count(distinct transaction_date) as average_order_value,
-- purchase Dates
min(transaction_date) as first_purchase,
max(transaction_date) as last_purcahse,
-- Customer_Lifespan
abs (max(transaction_date) - min(transaction_date) ) as customer_lifespan,
-- customer_recency
abs( (select max(transaction_date) from Analytical_Base_table) - MAx(transaction_date) ) as recency_days,
-- purchase frequency
case when abs(max(transaction_date) - min(transaction_date)) = 0
then count(distinct transaction_date) else count(distinct transaction_date) / 
((abs(max(transaction_date) - min(transaction_date)) + 1) / 30.0) end as purchase_frequency,
-- Diversity Metrics
count(distinct product_id) as distinct_product_purchased,
count(distinct product_brand) as distinct_brand_purchased,
count(distinct store_id) as distinct_stores_visited,
-- Customer_Tenure
abs (( select max(transaction_date) from Analytical_Base_table) - min(acct_open_date) )as customer_tenure
from Analytical_Base_table
group by customer_id, customer_name;

-- ===========================
-- RFM Score Calculation
-- ===========================
-- Assign recency, frequency and monetary scores
-- usings NTILE(5) window functions and generate RFM codes
drop table if exists Customer_RFM;
create table Customer_RFM as
with rfm_base as (
select customer_id, customer_name, recency_days, purchase_frequency, total_revenue, 
-- recency score 
ntile(5) over (order by recency_days asc) as recency_score,
-- frequency score
ntile(5) over (order by purchase_frequency desc) as frequency_score,
-- Monetary score
ntile(5) over (order by total_revenue desc) as monetary_score
from Customer_Metrics
)
select customer_id, customer_name, recency_days, purchase_frequency,total_revenue,recency_score,frequency_score,monetary_score,
-- combined RFM code
cast(recency_score as text) || cast(frequency_score as text) || cast(monetary_score as text) as RFM_Code
from rfm_base;

-- ===========================
-- Customer Segmentation
-- ===========================
-- Classify customers into business segments
-- Champions, Loyal Customers, Potential Loyalist, New Customers, At Risk, Lost Customers and Others
drop table if exists Customer_segments;
create table Customer_Segments as 
select customer_id, customer_name, recency_days, purchase_frequency, total_revenue, recency_score, frequency_score, monetary_score,RFM_code,
case 
	-- best customers
	when recency_score >= 4
	and frequency_score >= 4
	and monetary_score >= 4
	then 'Champions'
	-- Frequent and high-value customers
	when recency_score >= 3
	and frequency_score >= 4
	and monetary_score >=3
	then 'Loyal Customers'
	-- Recently active and showing strong potential
	when recency_score >= 4
	and frequency_score >= 2
	and monetary_score >= 2
	then 'Potential Loyalists'
	-- Very recent but not yet highly engaged
	when recency_score = 5
	and frequency_score <= 2
	then 'New Customers'
	-- Previously valuable, but activity has declined
	when recency_score <= 2
	and frequency_score >= 3
	and monetary_score >= 3
	then 'At Risk'
	-- Long inactive, low engagement
	when recency_score <= 2
	and frequency_score <= 2
	and monetary_score <= 2
	then 'Lost Customers'
	-- everything else
	else 'others'
end as Customer_segment
from Customer_RFM;

-- ===========================
-- Final Business Takeways
-- ===========================
-- "Others" contributed 36.15% of total revenue, revealing a major segmentation blind spot 
-- New Customers contributed 33.9% of total revenue while representing only 11.5% of customers
-- "At Risk" customers accounted for 25.5% of the customer base, signaling significant churn risk
-- "Lost Customers though small in number, still demonstrated strong spending potential"
-- "Deluxe Supermarket" stores dominated Top 10 store rankings
-- "North West" emerged as the Highest-performing region
-- The business should refine segmentation, strengthen retention and launch proactive win-back strategies