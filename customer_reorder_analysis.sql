-- ============================================================
-- Customer Reorder Analysis — Online Retail Dataset
-- Dataset source: UCI / Kaggle "Online Retail Dataset"
-- ============================================================

-- ------------------------------------------------------------
-- 1. SETUP
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS online_retail_project_v2;
USE online_retail_project_v2;

-- Safe to re-run: drops any existing tables from a previous run first
DROP TABLE IF EXISTS raw_transactions, clean_transactions, orders, customers, products;

CREATE TABLE raw_transactions (
    InvoiceNo    VARCHAR(20),
    StockCode    VARCHAR(20),
    Description  VARCHAR(255),
    Quantity     INT,
    InvoiceDate  VARCHAR(30),
    UnitPrice    DECIMAL(10,2),
    CustomerID   VARCHAR(20),
    Country      VARCHAR(50)
) CHARACTER SET utf8mb4;

-- ------------------------------------------------------------
-- 2. IMPORT RAW DATA
-- (CSV placed in MySQL's secure_file_priv directory)
-- ------------------------------------------------------------
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/online_retail.csv'
INTO TABLE raw_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- RESULT: 541,909 rows imported (4 minor warnings on UnitPrice truncation, safe to ignore)

-- ------------------------------------------------------------
-- 3. DATA CLEANING
-- Remove cancellations (InvoiceNo starting with 'C'),
-- missing CustomerIDs, and invalid quantities
-- ------------------------------------------------------------
CREATE TABLE clean_transactions AS
SELECT * FROM raw_transactions
WHERE CustomerID IS NOT NULL AND CustomerID != ''
  AND InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0;
-- RESULT: 397,924 rows survived cleaning (out of 541,909)
--   9,288 were cancellations
--   135,080 had missing CustomerID
--   10,624 had Quantity <= 0
--   (overlap between these groups accounts for the difference)

ALTER TABLE clean_transactions MODIFY CustomerID INT;

-- ------------------------------------------------------------
-- 4. BUILD NORMALIZED TABLES
-- ------------------------------------------------------------
CREATE TABLE orders AS
SELECT InvoiceNo, CustomerID, StockCode, Quantity,
       STR_TO_DATE(InvoiceDate, '%Y-%m-%d %H:%i:%s') AS OrderDate,
       UnitPrice
FROM clean_transactions;
-- RESULT: 397,924 rows in orders

CREATE TABLE customers AS
SELECT DISTINCT CustomerID, Country FROM clean_transactions;
-- RESULT: 4,347 unique customers

CREATE TABLE products AS
SELECT DISTINCT StockCode, Description FROM clean_transactions;
-- RESULT: 3,897 unique products

ALTER TABLE customers MODIFY CustomerID INT;
ALTER TABLE orders MODIFY CustomerID INT;

-- ============================================================
-- ANALYSIS QUERIES
-- ============================================================

-- Total orders per customer (top 10)
SELECT c.CustomerID, c.Country, COUNT(o.InvoiceNo) AS total_orders
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Country
ORDER BY total_orders DESC
LIMIT 10;
-- RESULT (top 5 of 10):
--   17841  United Kingdom   7847 orders
--   14911  EIRE             5677 orders
--   14096  United Kingdom   5111 orders
--   12748  United Kingdom   4596 orders
--   14606  United Kingdom   2700 orders

-- Most purchased products by volume (top 10)
SELECT p.Description, SUM(o.Quantity) AS total_quantity_sold
FROM products p
JOIN orders o ON p.StockCode = o.StockCode
GROUP BY p.Description
ORDER BY total_quantity_sold DESC
LIMIT 10;
-- RESULT (top 5 of 10):
--   PAPER CRAFT, LITTLE BIRDIE             80995 units
--   MEDIUM CERAMIC TOP STORAGE JAR         77916 units
--   WORLD WAR 2 GLIDERS ASSTD DESIGNS      54415 units
--   SMALL POPCORN HOLDER                   49183 units
--   POPCORN HOLDER                         49183 units
-- (note: a few product names appear twice under different StockCodes
--  with identical totals — a data quality quirk worth flagging)

-- Customers overdue for reorder (no order in 45+ days,
-- relative to the dataset's last recorded date: 2011-12-09)
SELECT c.CustomerID, c.Country,
       MAX(o.OrderDate) AS last_order_date,
       DATEDIFF('2011-12-09', MAX(o.OrderDate)) AS days_since_last_order
FROM customers c
JOIN orders o ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.Country
HAVING days_since_last_order > 45
ORDER BY days_since_last_order DESC
LIMIT 20;

-- Exact count of overdue customers
SELECT COUNT(*) AS overdue_customers
FROM (
    SELECT c.CustomerID
    FROM customers c
    JOIN orders o ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
    HAVING DATEDIFF('2011-12-09', MAX(o.OrderDate)) > 45
) AS overdue;
-- RESULT: 2,265 overdue customers (about 52% of the 4,347 total)

-- Average order value
SELECT AVG(Quantity * UnitPrice) AS avg_order_value FROM orders;
-- RESULT: 22.394748 (avg order value, in GBP)
