/*
Project: Return Impact & Profitability Analysis
Objective: Analyze the impact of product retunrs on overall business performamce including revenue loss, cost impact, net profitability and behavioral patterns across profuct, brand, region and time dimensions

KEy Questions: 
1. What is the overall return rate across the business?
2. How much revenue and cost is lost due to returns?
3. How do returns impact net revenue and net profit?
4. Which products, brends, regions and stores are most impacted?
5. How does return behavior vary over time?
6. Does return activity sognificantly affect profitability structure?

Notes:
- Transaction data is combined from multiple years for complete analysis
- Returns are analyzed at both revenue and cost impact level
- Profitability is measured after adjusting for return-driven revenue loss and cost loss
- ranking logic is used to identify top impacted entities
- Time intelligence is used to observe return behavior across months

Dataset Overview:
This analysis uses retail transactional data covering sales, returns, product catalog, store hierarchy, region mapping and calendar time dimensions to evaluate returnd-driven business impact.

Tables used:
- Transactions
- Returns
- Product
- Store 
- Region
- Calendar

Table Relationsips:
- Transactions.product_id -> Product.product_id
- Transactions.store_id -> Store.store_id
- Store.region_id -> Region.region_id
- Returns.product_id -> Product.product_id
- Retruns.store_id -> store.store_id
- Calendar.calendar_date -> Transactions.transaction_date
- calendar.return_date -> Retruns.return_date

Data Limitations:
-- Return are assumed to match directly with prodoct and store records
-- No customer-level linakge available for return behavior 
-- Profitability assumes static product cost and retail price
-- Some region/store combinations may have missing return activity 
-- Time-based analysis depends in calendar mapping completeness
 */

-- ==========================
-- Data Integration & Sanity Check
-- ==========================
-- combine transcations data from multiple years into single table
create table Transactions as
select * 
from "Transaction 1997"
union all 
select * 
from "Transaction 1998";
-- Validate row counts across all core table
select count(*)
from Transactions;
select count(*) 
from Calendar;
select count(*)
from Product;
select count(*)
from Store;
select count(*)
from Region;
select count(*)
from Returns;

-- ==========================
-- Data Quality Check
-- ==========================
-- Identify invalid or missing values in key fields 
select quantity
from Transactions
where quantity <= 0 or quantity is null;
select product_id
from Product
where product_id <= 0 or product_id is null;
select region_id
from Region
where region_id <= 0 or region_id is null;
select return_date
from Returns
where return_date <= 0 or return_date is null;
select store_id
from Store
where store_id <= 0 or store_id is null;
select "date"
from Calendar
where "date" <= 0 or "date" is null;
-- Check relationships between tables for missing mappings
select *
from Transactions t
left join product p on p.product_id = t.product_id;
select *
from Transactions t
left join Store s on s.store_id = t.store_id;
select *
from Store s
left join Region r on s.region_id = r.region_id;
select * 
from Returns r
left join Store s on r.store_id = s.store_id;
select *
from Returns r
left join Product p on r.product_id = p.product_id;

-- ==========================
-- Business Revenue Metrics
-- ==========================
-- Calculate total sales, revenue and cost
-- Total Quantity Sold
select sum(quantity) as Quantity_sold
from Transactions t;
-- Total Revenue Generated 
select sum(t.quantity * p.product_retail_price) as Total_Revenue
from Transactions t
Left join Product p on t.product_id = p.product_id;
-- Total Cost of goods sold
select sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join Product p on t.product_id = p.product_id;
-- Gross Profit before return impact
select sum(t.quantity * p.product_retail_price) -  sum(t.quantity * p.product_cost) as Gross_Profit
from Transactions t
left join Product p on t.product_id = p.product_id;

-- ==========================
-- Return Impact Analysis
-- ==========================
-- Measure total returned quantity and return rate
select sum(quantity) as Returned_Quantity
from Returns;
with Sales as (
select sum(quantity) as quantity_sold
from Transactions ),
Return as (
select sum(quantity) as quantity_returned
from Returns )
select r.quantity_returned, s.quantity_sold , round(r.quantity_returned * 100.0 / s.quantity_sold, 2) as Return_Rate
from sales s
cross join Return r ;
-- Revenue Loss on returned products
select sum(r.quantity *product_retail_price) as Return_Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id; 
-- Cost Loss due to returns
select sum(r.quantity * p.product_cost) as Return_Cost_Loss
from Returns r
left join product p on p.product_id = r.product_id;

-- ==========================
-- Profitability Impact Analysis
-- ==========================
-- Evaluate impact of returns on revenue and profitability
with revenue as(
select  sum(t.quantity * p.product_retail_price) as Gross_Revenue
from Transactions t
left join product p on t.product_id = p.product_id),
loss as (
select sum(r.quantity *product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id)
select r.Gross_Revenue, l.Revenue_Loss, (r.Gross_Revenue - l.Revenue_loss) as Net_Revenue
from Revenue r
cross join loss l;
-- Calculated Net Profit and profit Margin
with revenue as (
select sum(t.quantity * p.product_retail_price) as Gross_Revenue
from Transactions t
left join product p on p.product_id = t.product_id),
loss as (
select sum(r.quantity * p.product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id= r.product_id),
cost as (
select sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join product p on p.product_id = t.product_id)
select rev.Gross_Revenue, l.Revenue_Loss, c.Total_Cost, (rev.Gross_Revenue - l.Revenue_Loss) as Net_Revenue, 
((rev.Gross_Revenue - l.Revenue_Loss) - c.Total_Cost) as Net_Profit, 
round( (((rev.Gross_Revenue - l.Revenue_Loss) - c.total_Cost) * 100.0) /(rev.Gross_Revenue - l.Revenue_Loss), 2 ) as Profit_Margin
From Revenue rev
cross join loss l
cross join cost c;

-- ==========================
-- Product-Level Return Impact
-- ==========================
-- Identify impact of returns on each product
-- Calculated product level return impact metrics
With Revenue as (
select p.product_id, p.product_name, sum(quantity) as Sold_Quantity, sum(t.quantity * p.product_retail_price) as Product_Revenue
from Transactions t
left join product p on p.product_id = t.product_id
group by p.product_id),
product_returned as (
select p.product_id, sum(quantity) as Returned_Quantity 
from Returns r
left join product p on p.product_id = r.product_id
group by p.product_id),
Loss as (
select p.product_id, sum(r.quantity * p.product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id
group by p.product_id),
Cost as (
select p.product_id, sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join product p on p.product_id = t.product_id
group by p.product_id)
select R.product_id, R.product_name, R.Sold_Quantity, R.Product_Revenue, coalesce(l.Revenue_Loss,0), coalesce(pr.Returned_Quantity,0), 
round((coalesce(pr.Returned_Quantity ,0)* 100.0 )/ (R.Sold_Quantity),2) as Return_Rate,
(R.Product_Revenue - coalesce(l.Revenue_Loss,0)) as Net_Revenue, 
((R.Product_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) as Net_Profit, 
round( (((R.Product_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) * 100.0)/ (R.Product_Revenue - coalesce(l.Revenue_Loss,0)), 2) as Profit_Margin
from Revenue R
left join product_returned pr on R.product_id = pr.product_id
left join Loss l on R.product_id = l.product_id
left join Cost c on R.product_id = c.product_id;

-- ==========================
-- Brand-Level Return Impact
-- ==========================
-- Evaluate return behavior across product brand
-- Calculated product brand level return impact metrics
With Revenue as (
select p.product_brand, sum(quantity) as Sold_Quantity, sum(t.quantity * p.product_retail_price) as Brand_Revenue
from Transactions t
left join product p on p.product_id = t.product_id
group by p.product_brand),
brand_returned as (
select p.product_brand, sum(quantity) as Returned_Quantity 
from Returns r
left join product p on p.product_id = r.product_id
group by p.product_brand),
Loss as (
select p.product_brand, sum(r.quantity * p.product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id
group by p.product_brand),
Cost as (
select p.product_brand, sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join product p on p.product_id = t.product_id
group by p.product_brand)
select R.product_brand, R.Sold_Quantity, R.brand_Revenue, coalesce(l.Revenue_Loss,0), coalesce(pr.Returned_Quantity,0), 
round((coalesce(pr.Returned_Quantity,0) * 100.0 )/ (R.Sold_Quantity),2) as Return_Rate,
(R.brand_Revenue - coalesce(l.Revenue_Loss,0)) as Net_Revenue, 
((R.brand_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) as Net_Profit, 
round( (((R.brand_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) * 100.0)/ (R.brand_Revenue - coalesce(l.Revenue_Loss,0)), 2) as Profit_Margin
from Revenue R
left join brand_returned pr on R.product_brand = pr.product_brand
left join Loss l on R.product_brand = l.product_brand
left join Cost c on R.product_brand = c.product_brand;

-- ==========================
-- Region-Level Return Impact
-- ==========================
-- Analyze ho return affect different regions
-- Calculated region-level return impact metrics
With Revenue as (
select r.region_id, sum(quantity) as Sold_Quantity, sum(t.quantity * p.product_retail_price) as Region_Revenue
from Transactions t
left join product p on p.product_id = t.product_id
left join store s on t.store_id = s.store_id
left join region r on s.region_id = r.region_id
group by r.region_id),
region_returned as (
select r.region_id, sum(quantity) as Returned_Quantity 
from Returns rt
left join store s on rt.store_id = s.store_id
left join region r on s.region_id = r.region_id
group by r.region_id),
Loss as (
select r.region_id, coalesce(sum(rt.quantity * p.product_retail_price),0) as Revenue_Loss
from Returns rt
left join product p on p.product_id = rt.product_id
left join store s on rt.store_id = s.store_id
left join region r on s.region_id = r.region_id
group by r.region_id),
Cost as (
select r.region_id, sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join product p on p.product_id = t.product_id
left join store s on t.store_id = s.store_id
left join region r on s.region_id = r.region_id
group by r.region_id)
select R.region_id, R.Sold_Quantity, R.Region_Revenue, coalesce(l.Revenue_Loss,0), coalesce(pr.Returned_Quantity,0), 
round((coalesce(pr.Returned_Quantity,0) * 100.0 )/ (R.Sold_Quantity),2) as Return_Rate,
(R.Region_Revenue - coalesce(l.Revenue_Loss,0) )as Net_Revenue, 
((R.Region_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) as Net_Profit, 
round( (((R.Region_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) * 100.0)/ (R.Region_Revenue - coalesce(l.Revenue_Loss,0)), 2) as Profit_Margin
from Revenue R
left join region_returned pr on R.region_id = pr.region_id
left join Loss l on R.region_id = l.region_id
left join Cost c on R.region_id = c.region_id;

-- ==========================
-- Store-Level Return Impact
-- ==========================
-- Analyze store-wise return performance
-- Calculated store-level return impact metrics
With Revenue as (
select s.store_id, s.store_name, sum(quantity) as Sold_Quantity, sum(t.quantity * p.product_retail_price) as Store_Revenue
from Transactions t
left join product p on p.product_id = t.product_id
left join store s on t.store_id = s.store_id
group by s.store_id),
store_returned as (
select s.store_id, sum(quantity) as Returned_Quantity 
from Returns rt
left join store s on rt.store_id = s.store_id
group by s.store_id),
Loss as (
select s.store_id, coalesce(sum(rt.quantity * p.product_retail_price),0) as Revenue_Loss
from Returns rt
left join product p on p.product_id = rt.product_id
left join store s on rt.store_id = s.store_id
group by s.store_id),
Cost as (
select s.store_id, sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join product p on p.product_id = t.product_id
left join store s on t.store_id = s.store_id
group by s.store_id)
select R.store_id, R.store_name, R.Sold_Quantity, R.Store_Revenue, coalesce(l.Revenue_Loss,0), coalesce(pr.Returned_Quantity,0), 
round((coalesce(pr.Returned_Quantity,0) * 100.0 )/ (R.Sold_Quantity),2) as Return_Rate,
(R.store_Revenue - coalesce(l.Revenue_Loss,0) ) as Net_Revenue, 
((R.Store_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) as Net_Profit, 
round( (((R.Store_Revenue - coalesce(l.Revenue_Loss,0)) - c.Total_Cost) * 100.0)/ (R.Store_Revenue - coalesce(l.Revenue_Loss,0)), 2) as Profit_Margin
from Revenue R
left join Store_returned pr on R.store_id = pr.store_id
left join Loss l on R.store_id = l.store_id
left join Cost c on R.store_id = c.store_id;

-- ==========================
-- Time Intelligence Analysis
-- ==========================
-- Analyze monthly return behavior, revenue loss adn profitability trends
With Revenue as (
select c.calendar_year_month, c.calendar_year, c.calendar_month_number, c.calendar_month_name, sum(quantity) as Sold_Quantity, sum(t.quantity * p.product_retail_price) as Monthly_Revenue
from Transactions t
left join product p on p.product_id = t.product_id
left join Calendar c on t.transaction_date = c.calendar_date
group by c.calendar_year_month),
month_returned as (
select c.calendar_year_month, sum(quantity) as Returned_Quantity 
from Returns rt
left join calendar c on rt.return_date = c.calendar_date
group by c.calendar_year_month),
Loss as (
select c.calendar_year_month, coalesce(sum(rt.quantity * p.product_retail_price),0) as Revenue_Loss
from Returns rt
left join product p on p.product_id = rt.product_id
left join calendar c on rt.return_date = c.calendar_date
group by c.calendar_year_month),
Cost as (
select c.calendar_year_month, sum(t.quantity * p.product_cost) as Total_Cost
from Transactions t
left join product p on p.product_id = t.product_id
left join calendar c on t.transaction_date = c.calendar_date
group by c.calendar_year_month)
select R.calendar_year_month, R.calendar_year, R.calendar_month_number, R.calendar_month_name, R.Sold_Quantity, R.Monthly_Revenue, coalesce(l.Revenue_Loss,0), coalesce(pr.Returned_Quantity,0), 
round((coalesce(pr.Returned_Quantity,0) * 100.0 )/ (R.Sold_Quantity),2) as Return_Rate,
(R.Monthly_Revenue - coalesce(l.Revenue_Loss,0) )as Net_Revenue, 
((R.Monthly_Revenue - coalesce(l.Revenue_Loss,0)) - ct.Total_Cost) as Net_Profit, 
round( (((R.Monthly_Revenue - coalesce(l.Revenue_Loss,0)) - ct.Total_Cost) * 100.0)/ (R.Monthly_Revenue - coalesce(l.Revenue_Loss,0)), 2) as Profit_Margin
from Revenue R
left join Month_returned pr on R.calendar_year_month = pr.calendar_year_month
left join Loss l on R.calendar_year_month = l.calendar_year_month
left join Cost ct on R.calendar_year_month = ct.calendar_year_month
order by R.calendar_year, R.calendar_month_number;

-- ==========================
-- Top Impact Analysis
-- ==========================
-- Identify top products, brands, region and stores by return rate and revenue loss
with Sales as (
select p.product_id,p.product_name, sum(quantity) as quantity_sold
from Transactions t
left join product p on t.product_id = p.product_id
group by p.product_id),
Returned as (
select p.product_id, sum(quantity) as quantity_returned
from Returns rt
left join product p on p.product_id = rt.product_id
group by p.product_id),
Ranked as (
select  s.product_id, s.product_name, coalesce(r.quantity_returned,0), s.quantity_sold , round(coalesce(r.quantity_returned,0) * 100.0 / s.quantity_sold, 2) as Return_Rate,
DENSE_RANK() over ( order by  round(coalesce(r.quantity_returned,0) * 100.0 / s.quantity_sold, 2) desc ) as product_Rank
from sales s
left join Returned r on r.product_id = s.product_id )
select *
from Ranked 
where product_Rank <=10;
-- Top 10 products by Revenue loss
with loss as (
select p.product_id, p.product_name, sum(r.quantity * p.product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id
group by p.product_id),
Ranked as (
select product_id, product_name, Revenue_Loss, DENSE_RANK() over ( order by Revenue_Loss desc) as Product_Ranking
from loss)
select *
from Ranked 
where Product_Ranking <= 10;
-- Top 10 Brand by revenue Loss
with loss as (
select p.product_brand, sum(r.quantity * p.product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id
group by p.product_brand),
Ranked as (
select product_brand, Revenue_Loss, DENSE_RANK() over ( order by Revenue_Loss desc) as Brand_Ranking
from loss)
select *
from Ranked 
where Brand_Ranking <= 10;
-- Top 10 region by Revenue loss
with loss as (
select r.region_id, p.product_name, sum(rt.quantity * p.product_retail_price) as Revenue_Loss
from Returns rt
left join product p on p.product_id = rt.product_id
left join store s on rt.store_id = s.store_id
left join region r on s.region_id = r.region_id
group by r.region_id),
Ranked as (
select region_id, Revenue_Loss, DENSE_RANK() over ( order by Revenue_Loss desc) as Region_Ranking
from loss)
select *
from Ranked 
where Region_Ranking <= 10;
-- Top 10 store by Revenue Loss
with loss as (
select s.store_id,  sum(r.quantity * p.product_retail_price) as Revenue_Loss
from Returns r
left join product p on p.product_id = r.product_id
left join store s on r.store_id = s.store_id
group by s.store_id),
Ranked as (
select store_id, Revenue_Loss, DENSE_RANK() over ( order by Revenue_Loss desc) as Store_Ranking
from loss)
select *
from Ranked 
where Store_Ranking <= 10;

-- ==========================
-- Final Business Takeaways
-- ==========================
-- Return rate contribute relatively small portion to overall revenue movement
-- Net revenue is reduced after adjusting for return-driven revenue loss
-- Cost structure has a stronger influence on net profitability than return behavior
-- Gross profit and net profit remain closely aligned after return adjustment
-- Profitability is primarily driven by cost efficiency rather than return behavior
-- Return impact is consistent but not the dominant driver of business performance

