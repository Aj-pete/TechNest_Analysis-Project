-- ============================================================
-- Script  : 02b_profiling_other_sheets.sql
-- Purpose : Profile Returns, Customer_Details, Marketing,
--           Product_Details before cleaning begins
-- ============================================================


-- ── SECTION B: RETURNS

-- B1. Row count
SELECT COUNT(*) AS total_return_rows
FROM raw_returns;

-- B2. Key null counts
SELECT
    SUM(CASE WHEN ReturnID         IS NULL THEN 1 ELSE 0 END) AS null_returnid,
    SUM(CASE WHEN SalesID          IS NULL THEN 1 ELSE 0 END) AS null_salesid,
    SUM(CASE WHEN ReturnReason     IS NULL THEN 1 ELSE 0 END) AS null_reason,
    SUM(CASE WHEN ReturnDate       IS NULL THEN 1 ELSE 0 END) AS null_returndate,
    SUM(CASE WHEN RefundAmount_USD IS NULL THEN 1 ELSE 0 END) AS null_refund
FROM raw_returns;

-- B3. Impossible values in Returns
SELECT
    SUM(CASE WHEN RefundAmount_USD > SellingPrice
        THEN 1 ELSE 0 END) AS refund_exceeds_price,
    SUM(CASE WHEN RestockingFee_USD < 0
        THEN 1 ELSE 0 END) AS neg_restocking_fee
FROM raw_returns r
JOIN raw_sales_data s ON r.SalesID = s.SalesID;

-- B4. Return reason breakdown -- what are customers saying?
SELECT
    ReturnReason,
    COUNT(*)                              AS return_count,
    ROUND(COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2)         AS pct_of_returns
FROM raw_returns
WHERE ReturnReason IS NOT NULL
GROUP BY ReturnReason
ORDER BY return_count DESC;

-- B5. Return rate overall
SELECT
    (SELECT COUNT(*) FROM raw_returns)    AS total_returns,
    (SELECT COUNT(*) FROM raw_sales_data) AS total_orders,
    ROUND(
        (SELECT COUNT(*) FROM raw_returns) * 100.0 /
        (SELECT COUNT(*) FROM raw_sales_data), 2
    ) AS overall_return_rate_pct;


-- ── SECTION C: CUSTOMER_DETAILS 

-- C1. Row count and null audit
SELECT
    COUNT(*)  AS total_customers,
    SUM(CASE WHEN Gender    IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN AgeBand   IS NULL THEN 1 ELSE 0 END) AS null_ageband,
    SUM(CASE WHEN State     IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN Region    IS NULL THEN 1 ELSE 0 END) AS null_region
FROM raw_customer_details;


-- C3. Gender variants -- see the exact mess
SELECT DISTINCT Gender, COUNT(*) AS cnt
FROM raw_customer_details
GROUP BY Gender
ORDER BY cnt DESC;

-- C4. Region variants
SELECT DISTINCT Region, COUNT(*) AS cnt
FROM raw_customer_details
GROUP BY Region
ORDER BY cnt DESC;

-- C5. Duplicate CustomerIDs
SELECT
    COUNT(*)                   AS total_rows,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT CustomerID) AS duplicate_count
FROM raw_customer_details;


-- ── SECTION D: MARKETING_CAMPAIGNS 

-- D1. Full campaign overview -- all 30 campaigns
SELECT
    CampaignName,
    ChannelName,
    Budget_USD,
    ActualSpend_USD,
    ROI_Pct,
    Impressions,
    Clicks,
    CTR_Pct,
    NewCustomersAcquired,
    OrdersAttributed,
    RevenueAttributed_USD
FROM raw_marketing_campaigns
ORDER BY RevenueAttributed_USD DESC;

-- D2. Flag problem campaigns
SELECT
    CampaignName,
    Budget_USD,
    ActualSpend_USD,
    ROI_Pct,
    Clicks,
    Impressions,
    CASE WHEN Budget_USD LIKE '%USD%'
         THEN 'TEXT FORMAT ISSUE'
         ELSE 'OK' END             AS budget_flag,
    CASE WHEN ROI_Pct < 0
         THEN 'NEGATIVE ROI'
         ELSE 'OK' END             AS roi_flag,
    CASE WHEN Clicks > Impressions
         THEN 'CLICKS > IMPRESSIONS'
         ELSE 'OK' END             AS click_flag
FROM raw_marketing_campaigns
ORDER BY ROI_Pct ASC;


-- ── SECTION E: PRODUCT_DETAILS 
-- E1. Full product table -- small enough to read entirely
SELECT
    ProductID,
    Brand,
    Category,
    ProductName,
    MRP,
    CostPrice,
    LaunchYear,
    DemandCluster,
    CASE WHEN CostPrice > MRP
         THEN 'COST EXCEEDS MRP'
         ELSE 'OK' END            AS pricing_flag,
    CASE WHEN LaunchYear > 2025
         THEN 'IMPOSSIBLE YEAR'
         ELSE 'OK' END            AS year_flag
FROM raw_product_details
ORDER BY pricing_flag DESC, year_flag DESC;