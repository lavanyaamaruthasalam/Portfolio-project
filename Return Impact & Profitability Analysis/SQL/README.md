# SQL Project – Return Impact Analysis

This project demonstrates the use of SQL to evaluate how product returns affect business performance. The analysis measures return-driven revenue loss, profitability impact, and profit margin stability across products, brands, stores, regions, and time periods.

## Objective

To quantify the financial impact of product returns by:

- Measuring return rates and revenue loss
- Comparing gross and net business performance
- Evaluating profitability after accounting for returns
- Identifying products, brands, stores, and regions most affected by returns
- Validating profit margin stability across key business dimensions

## Key Analysis Performed

- Calculated core business metrics:
  - Quantity Sold
  - Total Revenue
  - Total Cost
  - Gross Profit

- Measured return impact through:
  - Returned Quantity
  - Return Rate
  - Revenue Loss
  - Cost Loss

- Calculated profitability metrics:
  - Gross Revenue
  - Net Revenue
  - Net Profit
  - Profit Margin

- Analyzed return impact across:
  - Products
  - Brands
  - Stores
  - Regions
  - Time Periods

- Ranked highest-impact entities using return-related revenue loss

## Key Insights

- Product returns contributed a relatively small portion of overall revenue movement
- Revenue loss caused by returns was significantly lower than total business cost, indicating limited direct impact on profitability
- Gross Profit and Net Profit remained closely aligned despite return activity
- Profit margins remained stable across products, brands, stores, regions, and time periods
- Business profitability was primarily influenced by cost structure rather than return behavior
- A small number of products and brands accounted for a disproportionate share of return-related revenue loss

## Tools Used

- SQL Joins
- Aggregations
- Common Table Expressions (CTEs)
- Window Functions (`DENSE_RANK()`)
- Conditional Logic
- Profitability Analysis
- Return Impact Analysis

## Project Outcome

This project transformed raw transaction and return data into a structured profitability assessment framework. The analysis demonstrated that returns had a limited effect on overall business profitability, while cost structure remained the primary driver of profit performance. The results provide a foundation for return management, profitability monitoring, and operational decision-making.
