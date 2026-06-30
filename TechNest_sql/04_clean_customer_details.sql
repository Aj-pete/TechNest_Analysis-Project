-- ==========================+++++++++++========================
-- Script  : 04_clean_customer_details.sql
-- Purpose : Clean raw_customer_details into analytical layer
-- Rule    : raw_customer_details is NEVER modified
-- ======================+++++++++***===============================


-- ── STEP 1: Deduplicate on CustomerID 

DROP TABLE IF EXISTS customer_deduped;

CREATE TABLE customer_deduped AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY CTID
        ) AS rn
    FROM raw_customer_details
) ranked
WHERE rn = 1;

SELECT COUNT(*) AS rows_after_dedup FROM customer_deduped;


-- ── STEP 2: Build the Clean Customer Table 

DROP TABLE IF EXISTS clean_customer_details;

CREATE TABLE clean_customer_details AS
SELECT

    CustomerID,
    CASE
        WHEN SignupDate ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_DATE(LEFT(SignupDate, 10), 'YYYY-MM-DD')
        WHEN SignupDate ~ '^\d{2}-[A-Za-z]{3}-\d{4}'
            THEN TO_DATE(SignupDate, 'DD-Mon-YYYY')
        WHEN SignupDate ~ '^\d{2}-\d{2}-\d{4}'
            THEN CASE
                WHEN CAST(LEFT(SignupDate, 2) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SUBSTRING(SignupDate, 7, 4) AS INTEGER),
                        CAST(SUBSTRING(SignupDate, 4, 2) AS INTEGER),
                        CAST(LEFT(SignupDate, 2)         AS INTEGER)
                    )
                ELSE
                    MAKE_DATE(
                        CAST(SUBSTRING(SignupDate, 7, 4) AS INTEGER),
                        CAST(LEFT(SignupDate, 2)         AS INTEGER),
                        CAST(SUBSTRING(SignupDate, 4, 2) AS INTEGER)
                    )
                END
        WHEN SignupDate ~ '^\d{2}/\d{2}/\d{4}'
            THEN CASE
                WHEN CAST(LEFT(SignupDate, 2) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SUBSTRING(SignupDate, 7, 4) AS INTEGER),
                        CAST(SUBSTRING(SignupDate, 4, 2) AS INTEGER),
                        CAST(LEFT(SignupDate, 2)         AS INTEGER)
                    )
                ELSE
                    MAKE_DATE(
                        CAST(SUBSTRING(SignupDate, 7, 4) AS INTEGER),
                        CAST(LEFT(SignupDate, 2)         AS INTEGER),
                        CAST(SUBSTRING(SignupDate, 4, 2) AS INTEGER)
                    )
                END
        ELSE NULL
    END AS SignupDate_Clean,

    -- ── GENDER
    CASE
        WHEN UPPER(TRIM(Gender)) IN ('M','MALE')   THEN 'Male'
        WHEN UPPER(TRIM(Gender)) IN ('F','FEMALE') THEN 'Female'
        ELSE 'Unknown'
    END AS Gender_Clean,

    -- ── AGE BAND
    COALESCE(TRIM(AgeBand), 'Unknown') AS AgeBand_Clean,

    -- SEGMENT
    COALESCE(TRIM(Segment), 'Unknown') AS Segment_Clean,

    ---TIER
    CASE
        WHEN UPPER(TRIM(Tier)) LIKE '%1%' THEN 'TIER-1'
        WHEN UPPER(TRIM(Tier)) LIKE '%2%' THEN 'TIER-2'
        WHEN UPPER(TRIM(Tier)) LIKE '%3%' THEN 'TIER-3'
        ELSE 'UNKNOWN'
    END AS Tier_Clean,

    -- ── CITY
    -- INITCAP converts 'new york' and 'NEW YORK' to 'New York'
    INITCAP(TRIM(City)) AS City_Clean,

    -- ── STATE
    COALESCE(UPPER(TRIM(State)), 'UNKNOWN') AS State_Clean,

    -- ── REGION
    CASE
        WHEN UPPER(TRIM(Region)) LIKE '%NORTH%' THEN 'NORTH'
        WHEN UPPER(TRIM(Region)) LIKE '%SOUTH%' THEN 'SOUTH'
        WHEN UPPER(TRIM(Region)) LIKE '%EAST%'  THEN 'EAST'
        WHEN UPPER(TRIM(Region)) LIKE '%WEST%'  THEN 'WEST'
        WHEN UPPER(TRIM(Region)) LIKE '%CENTRAL%' THEN 'CENTRAL'
        ELSE 'UNKNOWN'
    END AS Region_Clean,

    -- ── PREFERRED CHANNEL 
    CASE
        WHEN UPPER(TRIM(PreferredChannel)) LIKE '%AMAZON%'  THEN 'AMAZON'
        WHEN UPPER(TRIM(PreferredChannel)) LIKE '%EBAY%'    THEN 'EBAY'
        WHEN UPPER(TRIM(PreferredChannel)) LIKE '%WEBSITE%' THEN 'BRAND_WEBSITE'
        WHEN UPPER(TRIM(PreferredChannel)) LIKE '%WALMART%' THEN 'WALMART'
        ELSE UPPER(TRIM(PreferredChannel))
    END AS PreferredChannel_Clean,

    -- ── ACTIVITY WEIGHT 
    CASE
        WHEN ActivityWeight < 0 THEN NULL
        ELSE ActivityWeight
    END AS ActivityWeight_Clean,

    -- ── DATA QUALITY FLAG 
    CASE
        WHEN ActivityWeight < 0       THEN 'NEGATIVE_ACTIVITY'
        WHEN CustomerID IS NULL       THEN 'NULL_CUSTOMERID'
        ELSE 'VALID'
    END AS DQ_Flag

FROM customer_deduped;


-- ── STEP 3: Split into Analytical and Quarantine 

DROP TABLE IF EXISTS quarantine_customers;

CREATE TABLE quarantine_customers AS
SELECT *, NOW() AS quarantined_at
FROM clean_customer_details
WHERE DQ_Flag != 'VALID';

DROP TABLE IF EXISTS analytical_customers;

CREATE TABLE analytical_customers AS
SELECT *
FROM clean_customer_details
WHERE DQ_Flag = 'VALID';


-- ── STEP 4: Validation ────
SELECT
    (SELECT COUNT(*) FROM raw_customer_details)  AS raw_rows,
    (SELECT COUNT(*) FROM customer_deduped)      AS after_dedup,
    (SELECT COUNT(*) FROM analytical_customers)  AS clean_rows,
    (SELECT COUNT(*) FROM quarantine_customers)  AS quarantined_rows,
    ROUND(
        (SELECT COUNT(*) FROM quarantine_customers) * 100.0 /
        (SELECT COUNT(*) FROM raw_customer_details), 2
    )                                            AS quarantine_pct;