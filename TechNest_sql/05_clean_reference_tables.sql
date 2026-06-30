-- ============================================================
-- Script  : 05_clean_reference_tables.sql
-- Purpose : Clean Product_Details, Delivery_Partner_Data,
--           and Sales_Channel reference tables
-- Note    : Small tables -- no dedup step needed, row counts
--           are low enough to verify by eye
-- ============================================================


-- ══════=+++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TABLE 1: PRODUCT_DETAILS
-- Issues: Category casing, DemandCluster variants,
--         CostPrice > MRP in 2 rows, LaunchYear = 2099
-- ══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS analytical_products;

CREATE TABLE analytical_products AS
SELECT

    ProductID,
    TRIM(Brand)                    AS Brand,
    INITCAP(TRIM(SubCategory))     AS SubCategory,
    TRIM(ProductName)              AS ProductName,
    HeroFlag,
    PopularityWeight,

    -- ── CATEGORY
    CASE
        WHEN UPPER(TRIM(Category)) IN
            ('TRUE WIRELESS EARBUDS','TRUE WIRELESS','TWE')
            THEN 'TRUE_WIRELESS_EARBUDS'
        WHEN UPPER(TRIM(Category)) IN
            ('WIRED EARPHONES','EARPHONES')
            THEN 'WIRED_EARPHONES'
        WHEN UPPER(TRIM(Category)) IN
            ('HEADPHONES','HEAD PHONES','GAMING HEADPHONES')
            THEN 'HEADPHONES'
        WHEN UPPER(TRIM(Category)) IN
            ('NECKBANDS','NECK BAND')
            THEN 'NECKBANDS'
        WHEN UPPER(TRIM(Category)) IN
            ('SMART WATCHES','SMARTWATCH','SMART WATCH')
            THEN 'SMART_WATCHES'
        WHEN UPPER(TRIM(Category)) IN
            ('SOUNDBARS','SOUND BAR','SOUND BARS')
            THEN 'SOUNDBARS'
        WHEN UPPER(TRIM(Category)) IN
            ('WIRELESS SPEAKERS','BT SPEAKER','PARTY SPEAKERS',
             'BLUETOOTH SPEAKER')
            THEN 'WIRELESS_SPEAKERS'
        WHEN UPPER(TRIM(Category)) IN
            ('POWER BANKS','POWERBANK','POWER BANK')
            THEN 'POWER_BANKS'
        WHEN UPPER(TRIM(Category)) IN
            ('CHARGERS & CABLES','CHARGERS','CABLES',
             'CHARGERS AND CABLES')
            THEN 'CHARGERS_CABLES'
        WHEN UPPER(TRIM(Category)) IN
            ('PROJECTORS','PROJECTOR')
            THEN 'PROJECTORS'
        WHEN UPPER(TRIM(Category)) IN
            ('DASHCAMS','DASHCAM','DASH CAM')
            THEN 'DASHCAMS'
        ELSE UPPER(TRIM(Category))
    END AS Category_Clean,

    -- ── DEMAND CLUSTER
    CASE
        WHEN UPPER(TRIM(DemandCluster)) IN ('HERO')
            THEN 'HERO'
        WHEN UPPER(TRIM(DemandCluster)) IN
            ('LONGTAIL','LONG TAIL','LONG-TAIL')
            THEN 'LONG_TAIL'
        ELSE UPPER(TRIM(DemandCluster))
    END AS DemandCluster_Clean,

    -- ── LAUNCH YEAR: 2099 is impossible
    CASE
        WHEN LaunchYear > 2025 THEN NULL
        ELSE LaunchYear
    END AS LaunchYear_Clean,

    -- ── FINANCIALs
    MRP,
    CostPrice,

    -- Gross margin % at full price (no discount applied)
    CASE
        WHEN MRP > 0
            THEN ROUND((MRP - CostPrice) / MRP, 4)
        ELSE NULL
    END AS FullPrice_Margin_Pct,

    -- ── DATA QUALITY FLAG 
    CASE
        WHEN CostPrice > MRP  THEN 'COST_EXCEEDS_MRP'
        WHEN MRP < 1.50       THEN 'SUSPICIOUS_LOW_MRP'
        WHEN LaunchYear > 2025    THEN 'IMPOSSIBLE_LAUNCH_YEAR'
        ELSE 'VALID'
    END AS DQ_Flag

FROM raw_product_details;

-- Quick check
SELECT DQ_Flag, COUNT(*) FROM analytical_products GROUP BY 1;


-- ═══════════════════════---------------------------------------
-- TABLE 2: DELIVERY_PARTNER_DATA
-- Issues: Region casing, VehicleType variants,
--         Rating > 5.0, negative ExperienceYears
-- ══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS analytical_delivery_partners;

CREATE TABLE analytical_delivery_partners AS
SELECT

    DeliveryPartnerID,
    TRIM(PartnerName)              AS PartnerName,
    INITCAP(TRIM(HomeCity))        AS HomeCity_Clean,

    -- ── REGION
    CASE
        WHEN UPPER(TRIM(Region)) LIKE '%NORTH%'   THEN 'NORTH'
        WHEN UPPER(TRIM(Region)) LIKE '%SOUTH%'   THEN 'SOUTH'
        WHEN UPPER(TRIM(Region)) LIKE '%EAST%'    THEN 'EAST'
        WHEN UPPER(TRIM(Region)) LIKE '%WEST%'    THEN 'WEST'
        WHEN UPPER(TRIM(Region)) LIKE '%CENTRAL%' THEN 'CENTRAL'
        ELSE 'UNKNOWN'
    END AS Region_Clean,

    -- ── VEHICLE TYPe
    CASE
        WHEN UPPER(TRIM(VehicleType)) IN
            ('ELECTRIC BIKE','E-BIKE','EBIKE','E BIKE')
            THEN 'ELECTRIC_BIKE'
        WHEN UPPER(TRIM(VehicleType)) IN
            ('MOTORCYCLE','MOTORBIKE','MOTOR BIKE')
            THEN 'MOTORCYCLE'
        WHEN UPPER(TRIM(VehicleType)) IN
            ('VAN','CARGO VAN')
            THEN 'VAN'
        WHEN UPPER(TRIM(VehicleType)) IN
            ('BICYCLE','BIKE','PUSH BIKE')
            THEN 'BICYCLE'
        ELSE UPPER(TRIM(VehicleType))
    END AS VehicleType_Clean,

    -- ── RATING: cap at 5.0 -- anything above is impossible 
    --  NULL it rather than cap it so it does not
    -- artificially inflate partner ratings in analysis
    CASE
        WHEN Rating > 5.0 THEN NULL
        WHEN Rating < 0   THEN NULL
        ELSE Rating
    END AS Rating_Clean,

    -- ── EXPERIENCE YEARS: negative is impossible
    CASE
        WHEN ExperienceYears < 0 THEN NULL
        ELSE ExperienceYears
    END AS ExperienceYears_Clean,

    -- ── DATA QUALITY FLAG
    CASE
        WHEN Rating > 5.0          THEN 'INVALID_RATING'
        WHEN ExperienceYears < 0   THEN 'NEGATIVE_EXPERIENCE'
        ELSE 'VALID'
    END AS DQ_Flag

FROM raw_delivery_partner;
SELECT DQ_Flag, COUNT(*) FROM analytical_delivery_partners GROUP BY 1;


-- ═══════════════════-----------------------------------══════════
-- TABLE 3: SALES_CHANNEL
-- Issues: ChannelName variants, ChannelType variants,
--         BaseShare stored as text percentage, 1 null ChannelScope
-- ══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS analytical_sales_channel;

CREATE TABLE analytical_sales_channel AS
SELECT

    ChannelID,
    CASE
        WHEN UPPER(TRIM(ChannelName)) LIKE '%AMAZON%'  THEN 'Amazon'
        WHEN UPPER(TRIM(ChannelName)) LIKE '%EBAY%'    THEN 'eBay'
        WHEN UPPER(TRIM(ChannelName)) LIKE '%WALMART%' THEN 'Walmart'
        WHEN UPPER(TRIM(ChannelName)) LIKE '%WEBSITE%' THEN 'Brand Website'
        ELSE TRIM(ChannelName)
    END AS ChannelName_Clean,

    -- ── CHANNEL TYPE
    CASE
        WHEN UPPER(TRIM(ChannelType)) IN
            ('D2C','DIRECT TO CONSUMER','DIRECT')
            THEN 'D2C'
        WHEN UPPER(TRIM(ChannelType)) IN
            ('MARKETPLACE','MARKET PLACE')
            THEN 'MARKETPLACE'
        ELSE UPPER(TRIM(ChannelType))
    END AS ChannelType_Clean,

    COALESCE(TRIM(ChannelScope), 'UNKNOWN')  AS ChannelScope_Clean,
    TRIM(RegionScope)                         AS RegionScope,

    -- ── BASE SHARE: strip % and convert to decimal
    CASE
        WHEN BaseShare LIKE '%\%%' ESCAPE '\'
            THEN CAST(REPLACE(BaseShare,'%','') AS NUMERIC) / 100
        ELSE CAST(BaseShare AS NUMERIC)
    END AS BaseShare_Clean

FROM raw_sales_channel;

-- Quick check -- all 7 rows
SELECT * FROM analytical_sales_channel;


-- ══════════════════════════════════════════════════════════════
-- COMBINED VALIDATION
--══════════════════════
SELECT
    'Products'          AS table_name,
    (SELECT COUNT(*) FROM raw_product_details)           AS raw_rows,
    (SELECT COUNT(*) FROM analytical_products)           AS clean_rows,
    (SELECT COUNT(*) FROM analytical_products
     WHERE DQ_Flag != 'VALID')                           AS flagged_rows
UNION ALL
SELECT
    'Delivery Partners',
    (SELECT COUNT(*) FROM raw_delivery_partner_data),
    (SELECT COUNT(*) FROM analytical_delivery_partners),
    (SELECT COUNT(*) FROM analytical_delivery_partners
     WHERE DQ_Flag != 'VALID')
UNION ALL
SELECT
    'Sales Channel',
    (SELECT COUNT(*) FROM raw_sales_channel),
    (SELECT COUNT(*) FROM analytical_sales_channel),
    0;