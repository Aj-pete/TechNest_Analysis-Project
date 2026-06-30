-- ============================================================
-- Script  : 08_date_dimension_and_analysis.sql
-- Purpose : 1. Build date dimension for Power BI
--           2. Run the three headline analysis queries
--           3. Produce executive summary numbers
-- ==========------------------------------------------------------------------------------============


-- ═══════════════════=======================================════
-- PART 1: DATE DIMENSION
-- One row per calendar date covering the full data range
-- This enables YoY, MTD, rolling averages in Power BI
-- ══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date AS
WITH date_series AS (
    SELECT GENERATE_SERIES(
        (SELECT MIN(OrderDate_Clean) FROM analytical_sales),
        (SELECT MAX(OrderDate_Clean) FROM analytical_sales),
        INTERVAL '1 day'
    )::DATE AS calendar_date
)
SELECT
    calendar_date                                    AS Date,
    EXTRACT(YEAR  FROM calendar_date)::INTEGER       AS Year,
    EXTRACT(QUARTER FROM calendar_date)::INTEGER     AS Quarter,
    EXTRACT(MONTH FROM calendar_date)::INTEGER       AS MonthNum,
    TO_CHAR(calendar_date, 'Month')                  AS MonthName,
    TO_CHAR(calendar_date, 'Mon')                    AS MonthShort,
    EXTRACT(WEEK FROM calendar_date)::INTEGER        AS WeekNum,
    EXTRACT(DOW FROM calendar_date)::INTEGER         AS DayOfWeek,
    TO_CHAR(calendar_date, 'Day')                    AS DayName,
    CASE WHEN EXTRACT(DOW FROM calendar_date)
         IN (0, 6) THEN 1 ELSE 0 END                 AS Is_Weekend,
    -- Year-Month label for Power BI axis
    TO_CHAR(calendar_date, 'YYYY-MM')                AS YearMonth,
    -- Quarter label
    'Q' || EXTRACT(QUARTER FROM calendar_date)::TEXT
    || ' ' || EXTRACT(YEAR FROM calendar_date)::TEXT    AS QuarterLabel
FROM date_series;


SELECT
    MIN(Date)       AS earliest_date,
    MAX(Date)       AS latest_date,
    COUNT(*)        AS total_days
FROM dim_date;


-- ══════════════════════════════════════════════════════════════
-- PART 2: HEADLINE ANALYSIS QUERIES
-- These produce the numbers for executive summary
-- ══════════════════════════════════════════════════════════════


-- ── ANALYSIS 1: Discount Band Profitability ───────────────────
-- The single most important table in this project
SELECT
    Discount_Band,
    COUNT(*)                                            AS order_count,
    ROUND(SUM(NetSales), 2)                             AS total_revenue,
    ROUND(SUM(Profit), 2)                               AS total_profit,
    ROUND(AVG(Profit), 2)                               AS avg_profit_per_order,
    ROUND(AVG(Gross_Margin_Pct) * 100, 2)               AS avg_margin_pct,
    SUM(Is_Loss_Order)                                  AS loss_order_count,
    ROUND(SUM(Is_Loss_Order) * 100.0 / COUNT(*), 1)     AS loss_order_pct
FROM analytical_sales
WHERE OrderStatus_Clean = 'DELIVERED'
GROUP BY Discount_Band
ORDER BY Discount_Band;


-- ── ANALYSIS 2: Channel Profitability Decomposition
-- Answers: why is one channel more profitable than the other?

SELECT
    ChannelType_Clean,
    COUNT(*)                                            AS orders,
    ROUND(AVG(NetSales), 2)                             AS avg_order_value,
    ROUND(AVG(DiscountPct_Clean) * 100, 1)              AS avg_discount_pct,
    ROUND(AVG(COGS), 2)                                 AS avg_cogs,
    ROUND(AVG(ShippingCost_Clean), 2)                   AS avg_shipping,
    ROUND(AVG(Profit), 2)                               AS avg_profit,
    ROUND(SUM(Profit), 2)                               AS total_profit,
    ROUND(AVG(Gross_Margin_Pct) * 100, 2)               AS avg_margin_pct,
    ROUND(SUM(Is_Returned) * 100.0 / COUNT(*), 2)       AS return_rate_pct,
    ROUND(SUM(Is_SLA_Breach) * 100.0 / COUNT(*), 2)     AS sla_breach_pct
FROM analytical_sales
GROUP BY ChannelType_Clean
ORDER BY total_profit DESC;


-- ── ANALYSIS 3: Category Break-Even Gap 
-- For each category: what is the max discount before losing money
-- vs what discount is actually being applied?

SELECT
    ProductCategory_Clean,
    COUNT(*)                                            AS orders,
    ROUND(AVG(DiscountPct_Clean) * 100, 1)              AS avg_discount_applied_pct,
    ROUND(AVG(BreakEven_Discount_Rate) * 100, 1)        AS avg_breakeven_discount_pct,
    ROUND(
        (AVG(BreakEven_Discount_Rate) -
         AVG(DiscountPct_Clean)) * 100, 1)              AS discount_headroom_pct,
    ROUND(AVG(Profit), 2)                               AS avg_profit_per_order,
    ROUND(SUM(Profit), 2)                               AS total_profit,
    ROUND(SUM(Is_Loss_Order) * 100.0 / COUNT(*), 1)     AS loss_order_pct
FROM analytical_sales
WHERE OrderStatus_Clean = 'DELIVERED'
GROUP BY ProductCategory_Clean
ORDER BY avg_profit_per_order ASC;


-- ── ANALYSIS 4: Returns Impact on Profitability 
-- Total financial cost of returns to the business
SELECT
    -- Volume
    COUNT(*)                                            AS total_returns,
    COUNT(CASE WHEN Has_ReturnDate = 1 THEN 1 END)      AS returns_with_date,

    -- Financial impact
    ROUND(SUM(RefundAmount_USD), 2)                     AS total_refunded,
    ROUND(SUM(RestockingFee_USD), 2)                    AS total_restocking_fees,
    ROUND(SUM(NetRefund_USD), 2)                        AS total_net_refund_cost,
    ROUND(AVG(RefundAmount_USD), 2)                     AS avg_refund_per_return,

    -- Return reason breakdown
    ReturnReason_Clean,

    -- Average days to return (where date available)
    ROUND(AVG(CASE WHEN DaysToReturn_Clean IS NOT NULL
                   THEN DaysToReturn_Clean END), 1)     AS avg_days_to_return

FROM analytical_returns
GROUP BY ReturnReason_Clean
ORDER BY total_net_refund_cost DESC;


-- ── ANALYSIS 5: Campaign Profitability Reality Check 
-- Compares campaign attributed revenue vs what those
-- orders actually cost the business in profit

SELECT
    m.CampaignName,
    m.ChannelName,
    m.DQ_Flag,
    m.Budget_USD_Clean                                  AS budget,
    m.ActualSpend_USD                                   AS actual_spend,
    m.Budget_Variance_USD                               AS budget_variance,
    m.RevenueAttributed_USD                             AS attributed_revenue,
    m.Revenue_ROAS,
    m.ROI_Pct                                           AS reported_roi_pct,
    m.NewCustomersAcquired,
    m.OrdersAttributed,
    -- Cost per order acquired
    ROUND(m.ActualSpend_USD /
        NULLIF(m.OrdersAttributed, 0), 2)               AS cost_per_order
FROM analytical_marketing_campaigns m
ORDER BY m.ROI_Pct ASC;