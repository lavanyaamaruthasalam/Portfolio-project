# SQL Project – Customer Segmentation & RFM Analysis

This project demonstrates the use of SQL to build a complete customer analytics pipeline for RFM (Recency, Frequency, Monetary) segmentation. The analysis identifies high-value customers, customers at risk of churn, and actionable opportunities for retention and growth.

---

## Objective

To transform raw retail transaction data into structured customer intelligence by:
- Creating an Analytical Base Table (ABT)
- Calculating customer-level behavioral metrics
- Assigning RFM scores
- Segmenting customers into meaningful business groups
- Generating insights for retention, churn reduction, and revenue growth

---

## Key Analysis Performed

- Performed data quality checks for row counts, null values, invalid records, missing relationships, and duplicates
- Created a deduplicated transactions table (`Transactions_New`)
- Built an Analytical Base Table (`Analytical_Base_Table`) by joining Transactions, Customers, Products, Stores, and Regions
- Calculated revenue and profit at transaction level
- Generated customer-level metrics including:
  - Total Revenue and Profit
  - Total Orders and Quantity Purchased
  - Average Order Value
  - Recency
  - Purchase Frequency
  - Customer Lifespan
  - Product, Brand, and Store Diversity
  - Customer Tenure
- Applied `NTILE(5)` window functions to assign Recency, Frequency, and Monetary scores
- Created combined RFM codes
- Classified customers into business segments:
  - Champions
  - Loyal Customers
  - Potential Loyalists
  - New Customers
  - At Risk
  - Lost Customers
  - Others

---

## Key Insights

- The **Others** segment contributed **36.15% of total revenue**, making it the largest revenue-generating customer group
- **New Customers** contributed **33.9% of total revenue** while representing only **11.5% of the customer base**
- **2,255 customers (25.5% of the customer base)** were classified as **At Risk**
- **Lost Customers** represented only **3.88% of customers**, but maintained an average monetary value of **233.34**, indicating strong win-back potential
- Together, **New Customers + Others accounted for nearly 70% of total revenue**

---

## Tools Used

- SQL Joins
- Aggregations
- Common Table Expressions (CTEs)
- Window Functions (`NTILE()`)
- Conditional Logic (`CASE WHEN`)
- Analytical Base Table (ABT) Design

---

## Project Outcome

This project transformed raw transactional data into a structured customer segmentation model that reveals high-value customers, retention risks, and growth opportunities. The analysis provides a scalable foundation for customer lifecycle management, targeted marketing, and churn prevention strategies.
