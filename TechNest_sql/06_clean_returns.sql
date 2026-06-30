-- ============================================================
-- Script  : 06_clean_returns.sql
-- Purpose : Clean raw_returns into analytical layer
--           Includes orphan check against analytical_sales
-- ============================================================


-- ── STEP 1: Deduplicate on Retrns

DROP TABLE IF EXISTS returns_deduped;
CREATE TABLE returns_deduped AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ReturnID
            ORDER BY CTID
        ) AS rn
    FROM raw_returns
) ranked
WHERE rn = 1;

SELECT COUNT(*) AS rows_after_dedup FROM returns_deduped;

-- ── STEP 2 CORRECTED: No join. Clean dates only. 


DROP TABLE IF EXISTS clean_returns;

CREATE TABLE clean_returns AS
SELECT
    r.ReturnID,
    r.SalesID,
    r.CustomerID,
    r.ProductID,

    CASE
        WHEN r.OrderDate ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_DATE(LEFT(r.OrderDate, 10), 'YYYY-MM-DD')
        WHEN r.OrderDate ~ '^\d{2}-[A-Za-z]{3}-\d{4}'
            THEN TO_DATE(r.OrderDate, 'DD-Mon-YYYY')
        WHEN r.OrderDate ~ '^\d{2}-\d{2}-\d{4}'
            THEN CASE
                WHEN CAST(LEFT(r.OrderDate, 2) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SUBSTRING(r.OrderDate, 7, 4) AS INTEGER),
                        CAST(SUBSTRING(r.OrderDate, 4, 2) AS INTEGER),
                        CAST(LEFT(r.OrderDate, 2)         AS INTEGER))
                ELSE MAKE_DATE(
                        CAST(SUBSTRING(r.OrderDate, 7, 4) AS INTEGER),
                        CAST(LEFT(r.OrderDate, 2)         AS INTEGER),
                        CAST(SUBSTRING(r.OrderDate, 4, 2) AS INTEGER))
                END
        WHEN r.OrderDate ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN CASE
                WHEN CAST(SPLIT_PART(r.OrderDate,'/',1) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SPLIT_PART(r.OrderDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(r.OrderDate,'/',2) AS INTEGER),
                        CAST(SPLIT_PART(r.OrderDate,'/',1) AS INTEGER))
                ELSE MAKE_DATE(
                        CAST(SPLIT_PART(r.OrderDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(r.OrderDate,'/',1) AS INTEGER),
                        CAST(SPLIT_PART(r.OrderDate,'/',2) AS INTEGER))
                END
        ELSE NULL
    END AS OrderDate_Clean,
    CASE
        WHEN r.ReturnDate ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_DATE(LEFT(r.ReturnDate, 10), 'YYYY-MM-DD')
        WHEN r.ReturnDate ~ '^\d{1,2}-[A-Za-z]{3}-\d{4}$'
            THEN TO_DATE(r.ReturnDate, 'DD-Mon-YYYY')
        WHEN r.ReturnDate ~ '^\d{1,2}-[A-Za-z]{3}-\d{2}$'
            THEN TO_DATE(r.ReturnDate, 'DD-Mon-YY')
        WHEN r.ReturnDate ~ '^\d{2}-\d{2}-\d{4}$'
            THEN CASE
                WHEN CAST(LEFT(r.ReturnDate, 2) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SUBSTRING(r.ReturnDate, 7, 4) AS INTEGER),
                        CAST(SUBSTRING(r.ReturnDate, 4, 2) AS INTEGER),
                        CAST(LEFT(r.ReturnDate, 2)         AS INTEGER))
                ELSE MAKE_DATE(
                        CAST(SUBSTRING(r.ReturnDate, 7, 4) AS INTEGER),
                        CAST(LEFT(r.ReturnDate, 2)         AS INTEGER),
                        CAST(SUBSTRING(r.ReturnDate, 4, 2) AS INTEGER))
                END
        WHEN r.ReturnDate ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN CASE
                WHEN CAST(SPLIT_PART(r.ReturnDate,'/',1) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SPLIT_PART(r.ReturnDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(r.ReturnDate,'/',2) AS INTEGER),
                        CAST(SPLIT_PART(r.ReturnDate,'/',1) AS INTEGER))
                ELSE MAKE_DATE(
                        CAST(SPLIT_PART(r.ReturnDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(r.ReturnDate,'/',1) AS INTEGER),
                        CAST(SPLIT_PART(r.ReturnDate,'/',2) AS INTEGER))
                END
        ELSE NULL
    END AS ReturnDate_Clean,

    COALESCE(INITCAP(TRIM(r.ReturnReason)), 'Unknown') AS ReturnReason_Clean,
    INITCAP(TRIM(r.ReturnCondition))                   AS ReturnCondition_Clean,
    r.RefundAmount_USD,
    r.RestockingFee_USD,
    r.NetRefund_USD,
    INITCAP(TRIM(r.ReturnChannel))                     AS ReturnChannel_Clean,
    UPPER(TRIM(r.ReturnStatus))                        AS ReturnStatus_Clean,
    CASE
        WHEN UPPER(TRIM(r.IsApproved)) IN ('YES','Y','1','TRUE')
            THEN 1
        ELSE 0
    END AS IsApproved_Clean

FROM returns_deduped r;

SELECT COUNT(*) AS clean_returns_row_count FROM clean_returns;

-- ── STEP 3 FINAL: Join, calculate days, add flags 

DROP TABLE IF EXISTS clean_returns_final;

CREATE TABLE clean_returns_final AS
SELECT
    r.ReturnID,
    r.SalesID,
    r.CustomerID,
    r.ProductID,
    r.OrderDate_Clean,
    r.ReturnDate_Clean,

    -- Days to return calculated from already-clean dates
    CASE
        WHEN r.ReturnDate_Clean IS NOT NULL
         AND r.OrderDate_Clean  IS NOT NULL
         AND r.ReturnDate_Clean >= r.OrderDate_Clean
            THEN (r.ReturnDate_Clean - r.OrderDate_Clean)
        ELSE NULL
    END                                             AS DaysToReturn_Clean,

    r.ReturnReason_Clean,
    r.ReturnCondition_Clean,
    r.RefundAmount_USD,
    r.RestockingFee_USD,
    r.NetRefund_USD,
    r.ReturnChannel_Clean,
    r.ReturnStatus_Clean,
    r.IsApproved_Clean,

    -- Flag: does this row have a parsed return date?
    -- Rows without a date stay in analytical table
    -- but this flag excludes them from date-based analysis
    CASE
        WHEN r.ReturnDate_Clean IS NULL THEN 0
        ELSE 1
    END   AS Has_ReturnDate,

    -- DQ Flag: only impossible financial values quarantined
    CASE
        WHEN r.RefundAmount_USD > a.SellingPrice
            THEN 'REFUND_EXCEEDS_PRICE'
        WHEN r.RestockingFee_USD < 0
            THEN 'NEGATIVE_RESTOCKING_FEE'
        ELSE 'VALID'
    END          AS DQ_Flag,

    CASE
        WHEN a.SalesID IS NULL THEN 1
        ELSE 0
    END  AS Is_Orphaned_Return

FROM clean_returns r
LEFT JOIN (
    SELECT DISTINCT ON (SalesID)
        SalesID,
        SellingPrice
    FROM analytical_sales
    ORDER BY SalesID, CTID
) a ON r.SalesID = a.SalesID;


-- ── STEP 4: Split into Analytical and Quarantine 

DROP TABLE IF EXISTS quarantine_returns;

CREATE TABLE quarantine_returns AS
SELECT *, NOW() AS quarantined_at
FROM clean_returns_final
WHERE DQ_Flag != 'VALID'
   OR Is_Orphaned_Return = 1;

DROP TABLE IF EXISTS analytical_returns;

CREATE TABLE analytical_returns AS
SELECT *
FROM clean_returns_final
WHERE DQ_Flag = 'VALID'
  AND Is_Orphaned_Return = 0;


-- ── STEP 5: Validation 
SELECT
    (SELECT COUNT(*) FROM raw_returns)              AS raw_rows,
    (SELECT COUNT(*) FROM returns_deduped)          AS after_dedup,
    (SELECT COUNT(*) FROM analytical_returns)       AS clean_rows,
    (SELECT COUNT(*) FROM quarantine_returns)       AS quarantined_rows,
    (SELECT COUNT(*) FROM clean_returns_final
     WHERE Is_Orphaned_Return = 1)                  AS orphaned_returns,
    (SELECT COUNT(*) FROM analytical_returns
     WHERE Has_ReturnDate = 0)                      AS no_date_but_kept,
    ROUND(
        (SELECT COUNT(*) FROM quarantine_returns) * 100.0 /
        (SELECT COUNT(*) FROM raw_returns), 2
    )   AS quarantine_pct;