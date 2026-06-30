-- ============================================================
-- Script  : 01_create_raw_tables.sql
-- Purpose : Create all 8 raw tables exactly matching the CSV
--           structure. No cleaning. No transformation.
--           Raw tables are sacred -- never modify them.
-- Author  : [Your Name]
-- Date    : [Today's Date]
-- ============================================================


-- ── TABLE 1: Sales_Data ─────────────────────────────────────

DROP TABLE IF EXISTS raw_sales_data;

CREATE TABLE raw_sales_data (
    SalesID           INTEGER,
    OrderDate         TEXT,       
    OrderHour         INTEGER,
    CustomerID        INTEGER,
    ProductID         INTEGER,
    ChannelID         INTEGER,
    DeliveryPartnerID INTEGER,
    Quantity          NUMERIC,
    GrossMRPValue     NUMERIC,
    DiscountPct       TEXT,        
    DiscountAmount    NUMERIC,
    SellingPrice      NUMERIC,
    NetSales          NUMERIC,
    TaxRate           TEXT,       
    TaxAmount         NUMERIC,
    COGS              NUMERIC,
    ShippingCost      TEXT,       
    Profit            NUMERIC,
    PaymentMethod     TEXT,
    OrderStatus       TEXT,
    DeliveryDays      NUMERIC,
    CustomerTier      TEXT,
    CustomerSegment   TEXT,
    CityTier          TEXT,
    ChannelType       TEXT,
    IsFestivalPeriod  INTEGER,
    FestivalName      TEXT,
    IsWeekend         INTEGER,
    ProductCategory   TEXT,
    HeroFlag          INTEGER
);


-- ── TABLE 2: Customer_Details 
DROP TABLE IF EXISTS raw_customer_details;

CREATE TABLE raw_customer_details (
    CustomerID        INTEGER,
    SignupDate        TEXT,        
    Gender            TEXT,
    AgeBand           TEXT,
    Segment           TEXT,
    Tier              TEXT,
    City              TEXT,
    State             TEXT,
    Region            TEXT,
    PreferredChannel  TEXT,
    ActivityWeight    NUMERIC
);


-- ── TABLE 3: Product_Details 

DROP TABLE IF EXISTS raw_product_details;

CREATE TABLE raw_product_details (
    ProductID         INTEGER,
    Brand             TEXT,
    Category          TEXT,
    SubCategory       TEXT,
    ProductName       TEXT,
    HeroFlag          INTEGER,
    LaunchYear        INTEGER,
    MRP               NUMERIC,
    CostPrice         NUMERIC,
    PopularityWeight  NUMERIC,
    DemandCluster     TEXT
);


-- ── TABLE 4: Delivery_Partner_Data 

DROP TABLE IF EXISTS raw_delivery_partner_data;

CREATE TABLE raw_delivery_partner_data (
    DeliveryPartnerID INTEGER,
    PartnerName       TEXT,
    HomeCity          TEXT,
    Region            TEXT,
    VehicleType       TEXT,
    Rating            NUMERIC,
    ExperienceYears   NUMERIC
);


-- ── TABLE 5: Sales_Channel 
DROP TABLE IF EXISTS raw_sales_channel;

CREATE TABLE raw_sales_channel (
    ChannelID         INTEGER,
    ChannelName       TEXT,
    ChannelType       TEXT,
    ChannelScope      TEXT,
    RegionScope       TEXT,
    BaseShare         TEXT         
);


-- ── TABLE 6: Cleaning_Log 
DROP TABLE IF EXISTS raw_cleaning_log;

CREATE TABLE raw_cleaning_log (
    issue_num          INTEGER,
    Sheet              TEXT,
    Columns            TEXT,
    Issue_Type         TEXT,
    Issue_Description  TEXT,
    Est_Rows_Affected  TEXT,
    Action_Taken       TEXT,
    Date_Cleaned       TEXT,
    Analyst_Signoff    TEXT
);


-- ── TABLE 7: Returns

DROP TABLE IF EXISTS raw_returns;

CREATE TABLE raw_returns (
    ReturnID           TEXT,
    SalesID            INTEGER,
    CustomerID         INTEGER,
    ProductID          INTEGER,
    OrderDate          TEXT,        
    ReturnDate         TEXT,        
    DaysToReturn       INTEGER,
    ReturnReason       TEXT,
    ReturnCondition    TEXT,
    RefundAmount_USD   NUMERIC,
    RestockingFee_USD  NUMERIC,
    NetRefund_USD      NUMERIC,
    ReturnChannel      TEXT,
    ReturnStatus       TEXT,
    IsApproved         TEXT
);


-- ── TABLE 8: Marketing_Campaigns 

DROP TABLE IF EXISTS raw_marketing_campaigns;

CREATE TABLE raw_marketing_campaigns (
    CampaignID              TEXT,
    CampaignName            TEXT,
    ChannelID               INTEGER,
    ChannelName             TEXT,
    CampaignType            TEXT,
    TargetAudience          TEXT,
    StartDate               TEXT,    
    EndDate                 TEXT,    
    DurationDays            INTEGER,
    Budget_USD              TEXT,    
    ActualSpend_USD         NUMERIC,
    Impressions             INTEGER,
    Clicks                  INTEGER,
    CTR_Pct                 NUMERIC,
    NewCustomersAcquired    INTEGER,
    OrdersAttributed        INTEGER,
    RevenueAttributed_USD   NUMERIC,
    CostPerAcquisition_USD  NUMERIC,
    ROI_Pct                 NUMERIC
);