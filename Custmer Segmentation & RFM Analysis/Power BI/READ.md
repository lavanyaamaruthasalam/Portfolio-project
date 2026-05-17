# Customer Segmentation & RFM Analysis (Power BI)

This Power BI project analyzes customer behavior using RFM (Recency, Frequency, Monetary) segmentation to identify high-value customers, customers at risk of churn, and opportunities for retention and growth.

The dashboard focuses on answering key business questions such as:
- Who are the most valuable customer segments?
- Which customers are at risk of churn?
- How much revenue is driven by new and unidentified customer groups?
- Which regions and store formats contribute the most revenue?
- What actions should the business prioritize to improve retention and growth?

---

## Dashboard Overview

### 1. Customer Value Overview
![Customer Value Overview](screenshots/Customer Value Overview.png)

This view provides a high-level analysis of customer segment contribution, including:
- Total Revenue, Profit, Orders, and Customer Count
- Revenue contribution by customer segment
- Segment-level performance metrics
- Customer segment distribution
- Key business insights

#### Key Insight
- The **Others** segment contributes **36.15% of total revenue**, making it the largest revenue-generating group.
- **New Customers** contribute **33.9% of total revenue** while representing only **11.5% of the customer base**.
- Together, **New Customers + Others account for nearly 70% of total revenue**, indicating major opportunities for segmentation refinement and retention.

---

### 2. RFM Behavior Analysis
![RFM Behavior Analysis](screenshots/RFM Behavior Analysis.png)

This dashboard analyzes customer behavior using RFM scores and segment-level metrics, including:
- Average Recency, Frequency, and Monetary values
- Customer count by segment
- Segment-level RFM summary
- Behavioral comparison across customer groups

#### Key Insight
- **2,255 customers (25.5% of the customer base)** are classified as **At Risk**.
- **Lost Customers** represent only **3.88% of customers**, but maintain an average monetary value of **233.34**, indicating strong win-back potential.
- **New Customers** have the highest average monetary value (**612.17**), making retention a critical priority.

---

### 3. Geographic Performance Insights
![Geographic Performance Insights](screenshots/Geographic Performance Insights.png)

This view analyzes revenue performance across regions, store types, and individual stores, including:
- Interactive revenue map
- Revenue by sales region
- Revenue by store type
- Top 10 stores by revenue
- Store-level performance summary

#### Key Insight
- The **North West** region is the highest revenue-generating sales region.
- **All Top 10 stores by revenue are Deluxe Supermarkets**.
- Despite supermarkets generating slightly higher total revenue overall, Deluxe Supermarkets dominate top-store performance.

---

## Tools Used
- Power BI Desktop
- DAX Measures
- Data Modeling
- Interactive Visuals 
- Geographic Maps
- RFM Segmentation Dashboards

---

## Project Outcome

This dashboard reveals three immediate business priorities:

1. **Refine the "Others" segment** to better understand the largest revenue contributor.
2. **Retain high-spending New Customers** before they churn.
3. **Reactivate At-Risk and Lost Customers** through targeted win-back campaigns.

The analysis demonstrates how RFM segmentation can transform raw transactional data into actionable customer intelligence that supports retention, churn reduction, and strategic growth.
