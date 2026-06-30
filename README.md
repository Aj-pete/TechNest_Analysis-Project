# TechNest Electronics — Ecommerce Sales Intelligence Dashboard

**Client:** TechNest Electronics — US consumer electronics accessories brand  
**Tools:** PostgreSQL · Power BI · DAX  
**Dataset:** 8 tables · 994,500 raw transactions  
**Channels:** Amazon · eBay · Brand Website · Offline Retail  
**Status:** Complete — SQL cleaning, Power BI dashboard, executive summary  
**Dashboard file:** `Ecommerce_Sales_Intelligence.pbix` — requires Power BI Desktop to open

---

## Project Overview

### Note: Power BI report and raw_data can be downloaded and viewed via this link (https://drive.google.com/drive/folders/1qoBGqTCOl52Zq9tHF1UaQRUTj4qPhziS?usp=sharing)

A full end-to-end business intelligence engagement for TechNest Electronics, 
a US-based consumer electronics accessories brand selling across Amazon, eBay, 
Brand Website, and offline retail channels. The project diagnoses three 
structural business problems hidden beneath healthy top-line revenue figures 
and delivers eight pages of interactive intelligence across the company's 
sales, returns, customers, campaigns, products, and delivery operations.

This is not a tutorial project. Every analysis is framed around a specific 
strategic question the executive team is trying to answer. Every 
recommendation is quantified in dollars.

---

## Business Problems, Findings & Recommendations

| # | Business Question | Key Finding | Recommendation |
|---|---|---|---|
| 1 | At what discount depth does profitability collapse? | 85% of orders at 60%+ discount lose money. 29% of all delivered orders are loss-making. Break-even sits at the 40–50% band | Implement a category-level discount cap at 50%. Restrict Projectors to 29.7% max and Soundbars to 33.8% max — their structural break-even rates. Use the What-If simulator on Page 2 to quantify the exact profit recovery at each cap level |
| 2 | Why does online earn $180 less profit per order than offline? | Online carries 14 percentage points deeper average discounts than offline on the same products. Root cause is pricing policy, not channel structure | Align online discount rates with offline on a category-by-category basis. Begin with Soundbars and Projectors — profitable offline, loss-making online. Estimated annual profit recovery: ~$87M at current volumes |
| 3 | Which customer segments are genuinely valuable vs discount-hunters? | Working Professional and Young Professional deliver highest avg profit per order. Gamers and Students carry 64%+ avg discounts and lowest margins | Protect repeat customers (62% of revenue, 2.4× more profitable per order than one-time buyers). Redirect acquisition spend toward Working and Young Professional segments |
| 4 | What is the true cost of returns and how much is recoverable? | $27.8M in net refunds annually across 44,662 return transactions. $10.8M is operationally recoverable — $8.1M (Changed Mind) and $2.7M (Damaged in Transit) | Audit product content for top 20 products by Changed Mind return volume. Replace the bottom 20% of delivery partners by rating — partners below 3.5 stars drive 7%+ damage rates vs 1.2% for top-rated partners |
| 5 | Which campaigns are genuinely profitable vs burning budget? | 2 of 30 campaigns have negative ROI (Spring Retargeting, Year End Walmart Promo). 20 of 30 campaigns overspent approved budgets by a combined $66,044 | Pause both negative ROI campaigns immediately. Implement Finance Director sign-off required before any campaign exceeds its approved budget. Fix tracking on Independence Day Sales before relaunch — clicks exceed impressions, making ROI figure unreliable |
| 6 | Which delivery partners are costing the business money? | SLA breach rate is systemic at ~11% across all regions — not a regional problem but a network-wide capacity issue. Partners rated below 3.5 stars drive disproportionate damage-in-transit returns | Replace the bottom 20% of partners by rating. Review warehouse despatch timing — uniform regional breach rate indicates the problem begins before delivery, not during it |
| 7 | Is the business growing organically or only during promotions? | Non-promotional gross margin is 21.4% vs 14.5% blended. Promotional activity suppresses the reported margin by 6.9 percentage points. Festival periods drive 69% of revenue at 10.2% margin vs 21.4% outside them | Finance Director should report non-promotional margin alongside blended margin. Set annual targets on organic margin, not blended. Flash sales should be timed to weekend evenings where natural demand peaks — not Monday mornings |
| 8 | Which products are revenue illusions vs genuine performers? | SoundMax 500 ranks #4 by revenue but #12 by profit — a Revenue Illusion driven by 68% avg discount. Hero flag covers 94.6% of products with only 9.8% profit premium over Non-Hero | Redefine Hero flag as top 30% by profit rank only. Brands C and E require discount strategy review — large revenue bars with critically thin or negative profit contributions |

---

## Dataset

| Table | Rows | Description |
|---|---|---|
| Sales_Data | 994,500 | Transaction fact table — orders, revenue, profit, discount |
| Customer_Details | 153,000 | Customer demographics, segments, city tier |
| Product_Details | 106 | Product master — brand, category, MRP, cost price |
| Returns | 45,848 | Return transactions — reason, refund amount, condition |
| Marketing_Campaigns | 30 | Campaign performance — budget, spend, ROI, attributed orders |
| Delivery_Partner_Data | 180 | Partner ratings, vehicle type, region |
| Sales_Channel | 7 | Channel lookup — Amazon, eBay, Brand Website, Offline |
| Cleaning_Log | 53 rows | Pre-existing audit log from previous analyst — inherited and completed |

---

## Technical Approach

### SQL — Data Cleaning

All 8 raw tables cleaned using documented, reproducible PostgreSQL scripts. 
Every script creates a new table from the raw source — raw tables are 
never modified, preserving a full audit trail.

Key cleaning decisions:

- **OrderDate:** 4 mixed date formats (ISO, DD-Mon-YYYY, DD-MM-YYYY, DD/MM/YYYY) 
  resolved using CASE + LIKE pattern detection + MAKE_DATE() for unambiguous 
  date construction. TO_DATE() avoided due to PostgreSQL evaluation behaviour 
  with nested CASE expressions when both DD-MM and MM-DD formats appear under 
  the same regex pattern.

- **Negative profit rows (29% of dataset):** Retained in the analytical table 
  with an Is_Loss_Order binary flag. Not quarantined. Negative profit is a 
  confirmed business signal, not a data error — removing it would make the 
  business appear profitable when it is structurally not.

- **Duplicate SalesIDs (19,500 rows, 1.96%):** Resolved using ROW_NUMBER() 
  OVER (PARTITION BY SalesID ORDER BY CTID) — kept first occurrence per ID.

- **ShippingCost column:** Stored as TEXT with a dollar sign prefix on some 
  values. REPLACE + TRY_CAST pattern used to strip the symbol and cast to 
  FLOAT. Negative values NULLed and documented.

- **Categorical standardisation:** OrderStatus (12→3), PaymentMethod (19→5), 
  ProductCategory (39→11), CustomerTier (15→3), CityTier (12→3), 
  ChannelType (6→2) — all resolved using UPPER + TRIM + CASE mapping.

- **Derived columns built in SQL:** Discount_Band, BreakEven_Discount_Rate, 
  Gross_Margin_Pct, Is_Loss_Order, Is_Returned, Is_SLA_Breach, 
  OrderTimeOfDay — pre-computed once at cleaning time rather than 
  recalculated by Power BI on every refresh.

**Quarantine rate:** 0.78% of Sales_Data rows quarantined (7,732 rows). 
All quarantined rows preserved in a separate table with reason codes 
for audit purposes.

### Power BI — Data Model and Dashboard

**Star schema:** `analytical_sales` as fact table. Four dimension tables 
connected via CustomerID, ProductID, DeliveryPartnerID, ChannelID. 
`dim_date` connected via OrderDate_Clean for time intelligence. 
`analytical_returns` connected via SalesID.

**70 DAX measures** across 7 groups:
- Core revenue and profit (7)
- Discount and loss analysis (5)
- Time intelligence including YoY, YTD, rolling 90-day (8)
- Returns analysis (11)
- Operations and delivery (10)
- Campaign intelligence (11)
- What-If simulator, channel decomposition, customer segments (18)

All aggregation, ranking, and cross-table analysis — discount band 
profitability, channel gap decomposition, category break-even comparison, 
return reason financial breakdown, delivery partner performance, campaign 
efficiency, and segment profitability — is computed live in DAX, responding 
dynamically to the report's slicers and filter context.

**What-If Discount Cap Simulator:** DAX parameter measure using 
SELECTEDVALUE() to extract slicer scalar for real-time profit 
simulation. Allows the CCO to model the profit impact of any 
discount ceiling between 20% and 80% live in the dashboard.

---

## Dashboard Pages

| Page | Name | Audience | Business Questions |
|---|---|---|---|
| 1 | Executive Command Centre | CCO, Finance Director | All 8 — overview |
| 2 | Discount Intelligence | Finance Director, CCO | BQ1 |
| 3 | Channel & Category Analysis | Commercial Director | BQ2 |
| 4 | Returns Deep Dive | Operations, Finance | BQ4 |
| 5 | Customer Intelligence | Marketing, CRM | BQ3 |
| 6 | Product & Brand Intelligence | Category Manager | BQ8 |
| 7 | Campaign Performance | Head of Marketing | BQ5 |
| 8 | Operations & Seasonal Intelligence | Head of Operations | BQ6, BQ7 |

> **To view the dashboard:** Download `Ecommerce_Sales_Intelligence.pbix` 
> and open with Power BI Desktop (free download at microsoft.com/power-bi). 
> Ensure a PostgreSQL connection is available, or switch the data source 
> to import mode before opening.

---

## Repository Structure

```
ecommerce-sales-intelligence/
│
├── sql/
│   ├── 01_create_raw_tables.sql
│   ├── 02_baseline_profiling.sql
│   ├── 03_clean_sales_data.sql
│   ├── 04_clean_customer_details.sql
│   ├── 05_clean_reference_tables.sql
│   ├── 06_clean_returns.sql
│   ├── 07_clean_marketing_campaigns.sql
│   └── 08_date_dimension.sql
│
├── docs/
│   ├── Executive_Summary.pdf
│   
│
├── Ecommerce_Sales_Intelligence.pbix
└── README.md
```

---

## Key Technical Decisions Explained

**Why PostgreSQL over MySQL?**  
PostgreSQL's MAKE_DATE() and window functions handle complex transformations 
more predictably. Syntax transfers directly to Snowflake, BigQuery, and 
Redshift — the enterprise data warehouses used in professional BI environments.

**Why quarantine rather than delete bad rows?**  
Deleted rows cannot be audited. The quarantine table allows the client to 
reconcile source system data against analytical outputs. A 0.78% quarantine 
rate is healthy. The quarantine table is its own analytical output — it 
documents data pipeline quality issues that need fixing upstream.

**Why MAKE_DATE() instead of TO_DATE() for mixed date formats?**  
The dataset contains both DD-MM-YYYY and MM-DD-YYYY formats under the same 
regex pattern. MAKE_DATE() takes explicit integer arguments for year, month, 
and day — bypassing format string interpretation entirely. Format is detected 
programmatically: if the first two digits exceed 12 they cannot be a month.

**Why was profit kept negative rather than corrected or excluded?**  
Profit equals NetSales minus COGS minus ShippingCost, and the arithmetic was 
validated as internally consistent across every row. The negative values 
reflect a genuine business condition — orders sold below cost at high discount 
rates — not a data quality defect. Excluding them would understate the scale 
of the discount problem this engagement was designed to surface.

**Why was derived business logic built in SQL rather than entirely in DAX?**  
Columns like Discount_Band and BreakEven_Discount_Rate do not change based on 
what a user clicks — they are properties of each transaction row. Computing 
them once in SQL at cleaning time, rather than recalculating them on every 
Power BI refresh, keeps the data preparation layer reproducible independently 
of the BI tool and reduces unnecessary recomputation in the model.

---

## Validation Trail

| Table | Raw Rows | Clean Rows | Quarantined | Rate |
|---|---|---|---|---|
| Sales_Data | 994,500 | 967,268 | 7,732 | 0.78% |
| Customer_Details | 153,000 | 148,608 | 1,392 | 0.91% |
| Product_Details | 106 | 106 | 0 (5 flagged) | 0% |
| Delivery_Partners | 180 | 180 | 0 (5 flagged) | 0% |
| Sales_Channel | 7 | 7 | 0 | 0% |
| Returns | 45,848 | 44,662 | 733 | 1.60% |
| Marketing_Campaigns | 30 | 30 | 0 (3 flagged) | 0% |

---

## About This Project

Built as a portfolio project simulating a real client BI engagement for 
TechNest Electronics — a US consumer electronics accessories company. 
The dataset is a raw, messy Excel file across 8 sheets with 11 confirmed 
data quality issues. The project was approached exactly as a professional 
engagement — stakeholder mapping, data audit before cleaning, documented 
SQL scripts, a star schema data model, and a written executive summary 
alongside the dashboard.

The analysis deliberately avoids generic findings. Every insight connects 
to a specific financial decision the executive team can make this quarter.

---

*SQL scripts available in this repository.*  
*Executive summary PDF available in the docs/ folder.*
