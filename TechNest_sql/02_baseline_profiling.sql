-- ============================================================
-- Script  : 02_baseline_profiling.sql
-- Purpose : Confirm data loaded correctly. Establish the
--           pre-cleaning baseline we will reference throughout
--           the project. Screenshot every result.
-- ============================================================


-- ── SECTION A: SALES_DATA 

-- A1. Row count -- confirm the full dataset loaded
SELECT COUNT(*) AS total_rows
FROM raw_sales_data;


-- A2. Null counts across every critical column
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN SalesID          IS NULL THEN 1 ELSE 0 END) AS null_salesid,
    SUM(CASE WHEN OrderDate        IS NULL THEN 1 ELSE 0 END) AS null_orderdate,
    SUM(CASE WHEN CustomerID       IS NULL THEN 1 ELSE 0 END) AS null_customerid,
    SUM(CASE WHEN ProductID        IS NULL THEN 1 ELSE 0 END) AS null_productid,
    SUM(CASE WHEN DiscountPct      IS NULL THEN 1 ELSE 0 END) AS null_discountpct,
    SUM(CASE WHEN ShippingCost     IS NULL THEN 1 ELSE 0 END) AS null_shippingcost,
    SUM(CASE WHEN TaxRate          IS NULL THEN 1 ELSE 0 END) AS null_taxrate,
    SUM(CASE WHEN CustomerSegment  IS NULL THEN 1 ELSE 0 END) AS null_segment,
    SUM(CASE WHEN DeliveryDays     IS NULL THEN 1 ELSE 0 END) AS null_deliverydays,
    SUM(CASE WHEN FestivalName     IS NULL THEN 1 ELSE 0 END) AS null_festivalname
FROM raw_sales_data;


-- A3. Financial range checks
SELECT
    MIN(GrossMRPValue)  AS min_mrp,
    MAX(GrossMRPValue)  AS max_mrp,
    MIN(NetSales)       AS min_netsales,
    MAX(NetSales)       AS max_netsales,
    MIN(Profit)         AS min_profit,
    MAX(Profit)         AS max_profit,
    MIN(Quantity)       AS min_qty,
    MAX(Quantity)       AS max_qty,
    MIN(DeliveryDays)   AS min_delivery_days,
    MAX(DeliveryDays)   AS max_delivery_days
FROM raw_sales_data;


-- A4. Categorical distinct value scan
SELECT DISTINCT OrderStatus    FROM raw_sales_data ORDER BY 1;
SELECT DISTINCT ChannelType    FROM raw_sales_data ORDER BY 1;
SELECT DISTINCT CustomerTier   FROM raw_sales_data ORDER BY 1;
SELECT DISTINCT CityTier       FROM raw_sales_data ORDER BY 1;
SELECT DISTINCT PaymentMethod  FROM raw_sales_data ORDER BY 1;
SELECT DISTINCT ProductCategory FROM raw_sales_data ORDER BY 1;
SELECT DISTINCT CustomerSegment FROM raw_sales_data ORDER BY 1;


-- A5. Date format sample 
SELECT DISTINCT OrderDate
FROM raw_sales_data
ORDER BY RANDOM()
LIMIT 20;


-- A6. Duplicate SalesID check
SELECT
    COUNT(*)                    AS total_rows,
    COUNT(DISTINCT SalesID)     AS unique_salesids,
    COUNT(*) - COUNT(DISTINCT SalesID) AS duplicate_count,
    ROUND(
        (COUNT(*) - COUNT(DISTINCT SalesID)) * 100.0 / COUNT(*), 2
    ) AS duplicate_pct
FROM raw_sales_data;


-- A7. The messy TEXT columns  
SELECT DISTINCT DiscountPct
FROM raw_sales_data
WHERE DiscountPct !~ '^\d+\.?\d*$'  -- values that are NOT pure numbers
LIMIT 20;

SELECT DISTINCT ShippingCost
FROM raw_sales_data
WHERE ShippingCost !~ '^\d+\.?\d*$'
LIMIT 20;

SELECT DISTINCT TaxRate
FROM raw_sales_data
WHERE TaxRate !~ '^\d+\.?\d*$'
LIMIT 20;


-- A8. Impossible values count -- our quarantine candidates
SELECT
    SUM(CASE WHEN GrossMRPValue <= 0 THEN 1 ELSE 0 END) AS neg_mrp_rows,
    SUM(CASE WHEN Quantity = 0       THEN 1 ELSE 0 END) AS zero_qty_rows,
    SUM(CASE WHEN NetSales <= 0      THEN 1 ELSE 0 END) AS zero_sales_rows,
    SUM(CASE WHEN Profit < 0         THEN 1 ELSE 0 END) AS neg_profit_rows,
    ROUND(
        SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2
    ) AS neg_profit_pct
FROM raw_sales_data;