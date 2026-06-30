-- ============================================================
-- Script  : 03_clean_sales_data.sql
-- Purpose : Transform raw_sales_data into two outputs:
--           1. clean_sales_data  — analysis-ready rows
--           2. quarantine_sales  — bad rows preserved for audit
-- Rule    : raw_sales_data is NEVER modified
-- ========================================================


-- ── STEP 1: Handle Duplicates

DROP TABLE IF EXISTS sales_deduped;

CREATE TABLE sales_deduped AS
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY SalesID
            ORDER BY CTID
        ) AS rn
    FROM raw_sales_data
) ranked
WHERE rn = 1;

-- Confirm
SELECT COUNT(*) AS rows_after_dedup FROM sales_deduped;


-- ── STEP 2: Build the Full Clean Table ──────────────────────

DROP TABLE IF EXISTS clean_sales_data;

CREATE TABLE clean_sales_data AS
SELECT
    SalesID,
    CustomerID,
    ProductID,
    ChannelID,
    DeliveryPartnerID,
    OrderHour,
  
   CASE
        -- Format 1: YYYY-MM-DD or YYYY-MM-DD HH:MM:SS
        WHEN OrderDate ~ '^\d{4}-\d{2}-\d{2}'
            THEN TO_DATE(LEFT(OrderDate, 10), 'YYYY-MM-DD')

        -- Format 2: DD-Mon-YYYY e.g. 15-Jan-2023 (unambiguous)
        WHEN OrderDate ~ '^\d{2}-[A-Za-z]{3}-\d{4}'
            THEN TO_DATE(OrderDate, 'DD-Mon-YYYY')

        -- Format 3: hyphen numeric -- DD-MM-YYYY or MM-DD-YYYY
        WHEN OrderDate ~ '^\d{2}-\d{2}-\d{4}'
            THEN CASE
                WHEN CAST(LEFT(OrderDate, 2) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SUBSTRING(OrderDate, 7, 4) AS INTEGER),
                        CAST(SUBSTRING(OrderDate, 4, 2) AS INTEGER),
                        CAST(LEFT(OrderDate, 2)         AS INTEGER)
                    )
                ELSE
                    MAKE_DATE(
                        CAST(SUBSTRING(OrderDate, 7, 4) AS INTEGER),
                        CAST(LEFT(OrderDate, 2)         AS INTEGER),
                        CAST(SUBSTRING(OrderDate, 4, 2) AS INTEGER)
                    )
                END

        -- Format 4: slash numeric -- DD/MM/YYYY or MM/DD/YYYY
        WHEN OrderDate ~ '^\d{2}/\d{2}/\d{4}'
            THEN CASE
                WHEN CAST(LEFT(OrderDate, 2) AS INTEGER) > 12
                    THEN MAKE_DATE(
                        CAST(SUBSTRING(OrderDate, 7, 4) AS INTEGER),
                        CAST(SUBSTRING(OrderDate, 4, 2) AS INTEGER),
                        CAST(LEFT(OrderDate, 2)         AS INTEGER)
                    )
                ELSE
                    MAKE_DATE(
                        CAST(SUBSTRING(OrderDate, 7, 4) AS INTEGER),
                        CAST(LEFT(OrderDate, 2)         AS INTEGER),
                        CAST(SUBSTRING(OrderDate, 4, 2) AS INTEGER)
                    )
                END

        ELSE NULL
    END AS OrderDate_Clean,
	
    CASE
        WHEN UPPER(TRIM(OrderStatus)) IN
            ('DELIVERED','DELIVER')         THEN 'DELIVERED'
        WHEN UPPER(TRIM(OrderStatus)) IN
            ('RETURNED','RETURN')           THEN 'RETURNED'
        WHEN UPPER(TRIM(OrderStatus)) IN
            ('CANCELLED','CANCELED','CANCEL') THEN 'CANCELLED'
        ELSE 'UNKNOWN'
    END AS OrderStatus_Clean,

    --── CHANNEL TYPE
    UPPER(TRIM(ChannelType)) AS ChannelType_Clean,

    -- ── CUSTOMER TIER
    CASE
        WHEN UPPER(TRIM(CustomerTier)) LIKE '%1%' THEN 'TIER-1'
        WHEN UPPER(TRIM(CustomerTier)) LIKE '%2%' THEN 'TIER-2'
        WHEN UPPER(TRIM(CustomerTier)) LIKE '%3%' THEN 'TIER-3'
        ELSE 'UNKNOWN'
    END AS CustomerTier_Clean,

    -- ── CITY TIER
    CASE
        WHEN UPPER(TRIM(CityTier)) LIKE '%1%' THEN 'TIER-1'
        WHEN UPPER(TRIM(CityTier)) LIKE '%2%' THEN 'TIER-2'
        WHEN UPPER(TRIM(CityTier)) LIKE '%3%' THEN 'TIER-3'
        ELSE 'UNKNOWN'
    END AS CityTier_Clean,

    -- ── CUSTOMER SEGMENT 
    COALESCE(TRIM(CustomerSegment), 'UNKNOWN') AS CustomerSegment_Clean,

    -- ── PAYMENT METHOD
    CASE
        WHEN UPPER(TRIM(PaymentMethod)) IN
            ('COD','C.O.D','CASH ON DELIVERY')
            THEN 'COD'
        WHEN UPPER(TRIM(PaymentMethod)) IN
            ('CREDIT/DEBIT CARD','CREDIT/DEBIT','CREDIT CARD',
             'DEBIT CARD')
            THEN 'CREDIT_DEBIT_CARD'
        WHEN UPPER(TRIM(PaymentMethod)) IN
            ('DIGITAL WALLET','WALLET','E-WALLET','EWALLET')
            THEN 'DIGITAL_WALLET'
        WHEN UPPER(TRIM(PaymentMethod)) IN
            ('NET BANKING','ONLINE BANKING','NETBANKING')
            THEN 'NET_BANKING'
        WHEN UPPER(TRIM(PaymentMethod)) IN
            ('PAYPAL')
            THEN 'PAYPAL'
        ELSE 'UNKNOWN'
    END AS PaymentMethod_Clean,

    -- ── PRODUCT CATEGORY
    CASE
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('TRUE WIRELESS EARBUDS','TRUE WIRELESS','TWE')
            THEN 'TRUE_WIRELESS_EARBUDS'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('WIRED EARPHONES','EARPHONES')
            THEN 'WIRED_EARPHONES'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('HEADPHONES','HEAD PHONES','GAMING HEADPHONES')
            THEN 'HEADPHONES'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('NECKBANDS','NECK BAND')
            THEN 'NECKBANDS'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('SMART WATCHES','SMARTWATCH','SMART WATCH')
            THEN 'SMART_WATCHES'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('SOUNDBARS','SOUND BAR','SOUND BARS')
            THEN 'SOUNDBARS'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('WIRELESS SPEAKERS','BT SPEAKER','PARTY SPEAKERS',
             'BLUETOOTH SPEAKER')
            THEN 'WIRELESS_SPEAKERS'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('POWER BANKS','POWERBANK','POWER BANK')
            THEN 'POWER_BANKS'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('CHARGERS & CABLES','CHARGERS','CABLES',
             'CHARGERS AND CABLES')
            THEN 'CHARGERS_CABLES'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('PROJECTORS','PROJECTOR')
            THEN 'PROJECTORS'
        WHEN UPPER(TRIM(ProductCategory)) IN
            ('DASHCAMS','DASHCAM','DASH CAM')
            THEN 'DASHCAMS'
        ELSE 'UNCATEGORISED'
    END AS ProductCategory_Clean,

    -- ── FINANCIALS
    GrossMRPValue,
    Quantity,
    NetSales,
    COGS,
    DiscountAmount,
    SellingPrice,
    TaxAmount,
    Profit,

    -- DiscountPct: strip % sign if present, cast to numeric
    CASE
        WHEN DiscountPct IS NULL THEN NULL
        WHEN DiscountPct ~ '%'
            THEN CAST(REPLACE(DiscountPct,'%','') AS NUMERIC) / 100
        ELSE CAST(DiscountPct AS NUMERIC)
    END AS DiscountPct_Clean,

    -- TaxRate: same as discountpct
    CASE
        WHEN TaxRate IS NULL THEN NULL
        WHEN TaxRate ~ '%'
            THEN CAST(REPLACE(TaxRate,'%','') AS NUMERIC) / 100
        ELSE CAST(TaxRate AS NUMERIC)
    END AS TaxRate_Clean,

    -- ShippingCost: same as taxrate plus null negatives
    CASE
        WHEN ShippingCost IS NULL THEN NULL
        WHEN REPLACE(ShippingCost,'$','')::NUMERIC < 0 THEN NULL
        ELSE CAST(REPLACE(ShippingCost,'$','') AS NUMERIC)
    END AS ShippingCost_Clean,

    -- ── DERIVED COLUMNS 
    CASE WHEN Profit < 0    THEN 1 ELSE 0 END AS Is_Loss_Order,
    CASE WHEN UPPER(TRIM(OrderStatus))
         IN ('RETURNED','RETURN')
         THEN 1 ELSE 0 END                    AS Is_Returned,
    CASE WHEN UPPER(TRIM(OrderStatus))
         IN ('CANCELLED','CANCELED','CANCEL')
         THEN 1 ELSE 0 END                    AS Is_Cancelled,
    CASE WHEN DeliveryDays > 3
         THEN 1 ELSE 0 END                    AS Is_SLA_Breach,
    DeliveryDays,

    -- Discount Band with letter prefix for correct PBI sort order
    -- A_ sorts before B_ sorts before C_ -- prevents chart chaos
    CASE
        WHEN CASE WHEN DiscountPct ~ '%'
                  THEN CAST(REPLACE(DiscountPct,'%','') AS NUMERIC)/100
                  ELSE CAST(DiscountPct AS NUMERIC) END < 0.20
            THEN 'A_Under 20%'
        WHEN CASE WHEN DiscountPct ~ '%'
                  THEN CAST(REPLACE(DiscountPct,'%','') AS NUMERIC)/100
                  ELSE CAST(DiscountPct AS NUMERIC) END < 0.30
            THEN 'B_20-30%'
        WHEN CASE WHEN DiscountPct ~ '%'
                  THEN CAST(REPLACE(DiscountPct,'%','') AS NUMERIC)/100
                  ELSE CAST(DiscountPct AS NUMERIC) END < 0.40
            THEN 'C_30-40%'
        WHEN CASE WHEN DiscountPct ~ '%'
                  THEN CAST(REPLACE(DiscountPct,'%','') AS NUMERIC)/100
                  ELSE CAST(DiscountPct AS NUMERIC) END < 0.50
            THEN 'D_40-50%'
        WHEN CASE WHEN DiscountPct ~ '%'
                  THEN CAST(REPLACE(DiscountPct,'%','') AS NUMERIC)/100
                  ELSE CAST(DiscountPct AS NUMERIC) END < 0.60
            THEN 'E_50-60%'
        ELSE 'F_60% Plus'
    END AS Discount_Band,

    -- Gross margin % per order
    CASE WHEN NetSales = 0 OR NetSales IS NULL THEN NULL
         ELSE ROUND(Profit / NetSales, 4)
    END AS Gross_Margin_Pct,

    -- Break-even discount per order
    -- The max discount at which this order would still profit
    CASE WHEN GrossMRPValue > 0
         THEN ROUND(1 - (COGS / GrossMRPValue), 4)
         ELSE NULL
    END AS BreakEven_Discount_Rate,

    -- Order time of day label
    CASE
        WHEN OrderHour BETWEEN 6  AND 11 THEN 'Morning'
        WHEN OrderHour BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN OrderHour BETWEEN 17 AND 21 THEN 'Evening'
        ELSE 'Night'
    END AS OrderTimeOfDay,

    -- Data quality flag for routing
    CASE
        WHEN GrossMRPValue <= 0  THEN 'INVALID_MRP'
        WHEN Quantity = 0        THEN 'ZERO_QUANTITY'
        WHEN NetSales <= 0       THEN 'ZERO_SALES'
        ELSE 'VALID'
    END AS DQ_Flag,

    IsFestivalPeriod,
    FestivalName,
    IsWeekend,
    HeroFlag

FROM sales_deduped;


-- ── STEP 3: Split into Analytical and Quarantine 

DROP TABLE IF EXISTS quarantine_sales;

CREATE TABLE quarantine_sales AS
SELECT *, NOW() AS quarantined_at
FROM clean_sales_data
WHERE DQ_Flag != 'VALID';

DROP TABLE IF EXISTS analytical_sales;

CREATE TABLE analytical_sales AS
SELECT *
FROM clean_sales_data
WHERE DQ_Flag = 'VALID';


-- ── STEP 4: Validation Check 
SELECT
    (SELECT COUNT(*) FROM raw_sales_data)    AS raw_rows,
    (SELECT COUNT(*) FROM sales_deduped)     AS after_dedup,
    (SELECT COUNT(*) FROM analytical_sales)  AS clean_rows,
    (SELECT COUNT(*) FROM quarantine_sales)  AS quarantined_rows,
    ROUND(
        (SELECT COUNT(*) FROM quarantine_sales) * 100.0 /
        (SELECT COUNT(*) FROM raw_sales_data), 2
    )                                        AS quarantine_pct;