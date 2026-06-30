-- ============================================================
-- Script  : 07_clean_marketing_campaigns.sql
-- Purpose : Clean raw_marketing_campaigns
--           30 rows -- no dedup needed, small enough to verify
-- ===============---------------------------------============

DROP TABLE IF EXISTS analytical_marketing_campaigns;

CREATE TABLE analytical_marketing_campaigns AS
SELECT

    TRIM(CampaignID)   AS CampaignID,
    TRIM(CampaignName)  AS CampaignName,
    ChannelID,
    TRIM(ChannelName) AS ChannelName,
    INITCAP(TRIM(CampaignType)) AS CampaignType,
    COALESCE(INITCAP(TRIM(TargetAudience)), 'Unknown') AS TargetAudience,
    CASE
        WHEN StartDate ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_DATE(LEFT(StartDate, 10), 'YYYY-MM-DD')
        WHEN StartDate ~ '^\d{1,2}-[A-Za-z]{3}-\d{4}$'
            THEN TO_DATE(StartDate, 'DD-Mon-YYYY')
        WHEN StartDate ~ '^\d{1,2}-[A-Za-z]{3}-\d{2}$'
            THEN TO_DATE(StartDate, 'DD-Mon-YY')
        WHEN StartDate ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN CASE
                WHEN CAST(SPLIT_PART(StartDate,'/',1) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SPLIT_PART(StartDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(StartDate,'/',2) AS INTEGER),
                        CAST(SPLIT_PART(StartDate,'/',1) AS INTEGER))
                ELSE MAKE_DATE(
                        CAST(SPLIT_PART(StartDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(StartDate,'/',1) AS INTEGER),
                        CAST(SPLIT_PART(StartDate,'/',2) AS INTEGER))
                END
        ELSE NULL
    END AS StartDate_Clean,

    CASE
        WHEN EndDate ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_DATE(LEFT(EndDate, 10), 'YYYY-MM-DD')
        WHEN EndDate ~ '^\d{1,2}-[A-Za-z]{3}-\d{4}$'
            THEN TO_DATE(EndDate, 'DD-Mon-YYYY')
        WHEN EndDate ~ '^\d{1,2}-[A-Za-z]{3}-\d{2}$'
            THEN TO_DATE(EndDate, 'DD-Mon-YY')
        WHEN EndDate ~ '^\d{1,2}/\d{1,2}/\d{4}$'
            THEN CASE
                WHEN CAST(SPLIT_PART(EndDate,'/',1) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SPLIT_PART(EndDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(EndDate,'/',2) AS INTEGER),
                        CAST(SPLIT_PART(EndDate,'/',1) AS INTEGER))
                ELSE MAKE_DATE(
                        CAST(SPLIT_PART(EndDate,'/',3) AS INTEGER),
                        CAST(SPLIT_PART(EndDate,'/',1) AS INTEGER),
                        CAST(SPLIT_PART(EndDate,'/',2) AS INTEGER))
                END
        ELSE NULL
    END AS EndDate_Clean,

    DurationDays,

    -- ── BUDGET: strip "USD " prefix, cast to numeric 
    CASE
        WHEN Budget_USD LIKE 'USD%'
            THEN CAST(
                REPLACE(REPLACE(Budget_USD, 'USD ', ''), ',', '')
                AS NUMERIC)
        ELSE CAST(REPLACE(Budget_USD, ',', '') AS NUMERIC)
    END AS Budget_USD_Clean,

    ActualSpend_USD,
    Impressions,
    Clicks,
    CTR_Pct,
    NewCustomersAcquired,
    OrdersAttributed,
    RevenueAttributed_USD,
    CostPerAcquisition_USD,
    ROI_Pct,

    -- ── DERIVED: Budget variance
    -- Positive = underspent, Negative = overspent
    CASE
        WHEN Budget_USD LIKE 'USD%'
            THEN CAST(
                REPLACE(REPLACE(Budget_USD,'USD ',''),',','')
                AS NUMERIC) - ActualSpend_USD
        ELSE CAST(REPLACE(Budget_USD,',','') AS NUMERIC)
             - ActualSpend_USD
    END AS Budget_Variance_USD,

    -- ── DERIVED: Profit ROAS proxy
    -- Standard ROAS = Revenue / Spend
    CASE
        WHEN ActualSpend_USD > 0
            THEN ROUND(RevenueAttributed_USD / ActualSpend_USD, 2)
        ELSE NULL
    END AS Revenue_ROAS,

    -- ── DQ FLAGS
    --keep all 30 rows -- too few to quarantine
    CASE
        WHEN ROI_Pct < 0
            THEN 'NEGATIVE_ROI'
        WHEN Clicks > Impressions
            THEN 'CLICKS_EXCEED_IMPRESSIONS'
        WHEN ActualSpend_USD > CASE
                WHEN Budget_USD LIKE 'USD%'
                THEN CAST(REPLACE(REPLACE(Budget_USD,'USD ',''),
                          ',','') AS NUMERIC)
                ELSE CAST(REPLACE(Budget_USD,',','') AS NUMERIC)
             END
            THEN 'OVERSPENT_BUDGET'
        ELSE 'VALID'
    END AS DQ_Flag
FROM raw_marketing_campaigns;


-- ── VALIDATION 
-- All 30 rows kept 
SELECT
    DQ_Flag,
    COUNT(*)                        AS campaign_count,
    ROUND(SUM(Budget_USD_Clean), 2) AS total_budget,
    ROUND(SUM(ActualSpend_USD), 2)  AS total_spend,
    ROUND(AVG(ROI_Pct), 2)          AS avg_roi_pct
FROM analytical_marketing_campaigns
GROUP BY DQ_Flag
ORDER BY campaign_count DESC;