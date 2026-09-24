# Customer Reorder Analysis — Online Retail Dataset

## Overview
A SQL-based analysis of a UK-based online retailer's transaction data (Dec 2010–Dec 2011),
modeled after real-world reorder/retention analysis used by D2C and nutrition/pharmacy brands
(e.g., HealthKart, 1mg) where repeat purchases drive revenue.

## Dataset
- Source: [UCI / Kaggle "Online Retail Dataset"](https://archive.ics.uci.edu/dataset/352/online+retail)
- 541,909 raw transactions
- Cleaned to 397,924 rows by removing cancellations, missing CustomerIDs, and invalid quantities

## Database Design
Normalized into 3 tables in MySQL:
- `customers` (4,347 rows) — CustomerID, Country
- `products` (3,897 rows) — StockCode, Description
- `orders` (397,924 rows) — InvoiceNo, CustomerID, StockCode, Quantity, OrderDate, UnitPrice

## Key Findings
- **Customer concentration:** Top customer placed 7,847 orders, suggesting a wholesale/bulk-buyer
  segment within the customer base — most high-order customers are UK-based, with some in Ireland
  and the Netherlands.
- **Churn risk:** 2,265 customers (52% of the customer base) have not ordered in 45+ days,
  flagging a strong candidate list for a retention/reminder campaign.
- **Top product:** "Paper Craft, Little Birdie" led by volume (80,995 units). Noted some products
  appear under multiple StockCodes with near-identical names — a data quality issue worth flagging
  for a real business.
- **Average order value:** £22.39

## Skills Demonstrated
SQL data cleaning (nulls, cancellations, type mismatches), table normalization, JOINs,
GROUP BY/HAVING, date-based analysis (DATEDIFF, STR_TO_DATE), business-oriented insight generation.

## How to Run
1. Download the [Online Retail Dataset](https://archive.ics.uci.edu/dataset/352/online+retail) as a CSV.
2. Place the CSV in your MySQL server's secure file directory (find it via `SHOW VARIABLES LIKE 'secure_file_priv';`).
3. Update the `LOAD DATA INFILE` path in `customer_reorder_analysis.sql` to match your file location.
4. Run the script in MySQL Workbench (or any MySQL client) from top to bottom.

## Files
- `customer_reorder_analysis.sql` — full script: setup, import, cleaning, table creation, and analysis queries (with results included as comments)
