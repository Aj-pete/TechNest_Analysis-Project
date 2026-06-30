# TechNest Electronics — Executive Summary
## Ecommerce Sales Intelligence Engagement
**Prepared by:** [Your Name] | **Date:** [Date] | **Client:** TechNest Electronics  
**Engagement:** Ecommerce Sales Intelligence  
**Audience:** Chief Commercial Officer, Finance Director  
**Classification:** Internal — Strategic

---

## Situation

TechNest Electronics is generating strong top-line revenue growth across its 
ecommerce and offline channels, processing approximately 967,000 delivered orders 
annually across 11 product categories, 5 brands, and multiple sales channels 
including Amazon, eBay, Brand Website, and direct offline retail. Customer acquisition is 
active — 148,608 unique customers are on record — and the returns system, 
marketing campaigns, and delivery network are all operational. On headline 
revenue metrics, the business appears healthy.

---

## Complication

A profit-level analysis of the full transaction dataset reveals three structural 
problems that the headline revenue figures do not disclose.

**The discount structure is destroying margin at scale.** Approximately 29% of 
all delivered orders — nearly 1 in 3 — are loss-making. The business reaches a 
profit inflection point at the 50% discount threshold: below 50% discount, most 
orders are profitable; above 60% discount, 85% of orders lose money. Projectors 
and Soundbars are the only two categories discounted beyond their structural 
break-even rate, but the broader discount culture across all categories is 
compressing margin to a blended gross margin of 14.5% — against a non-promotional 
margin of 21.4%, meaning promotional activity is suppressing the reported margin 
picture by 6.9 percentage points.

**The online channel, which handles 73% of all order volume, earns $180.70 
less profit per order than the offline channel.** Online orders average $41.61 
profit per order against $222.31 for offline. Root cause analysis confirms this 
gap is primarily discount-driven — online orders carry an average discount 14 
percentage points deeper than equivalent offline orders on the same products. 
This is a pricing policy failure, not a structural channel problem. The financial 
implication is significant: closing half the channel gap at current online volumes 
would add approximately $87 million in annual profit.

**The returns system is costing $27.8 million in net refunds annually, of which 
$10.8 million is operationally recoverable.** The recoverable portion comprises 
$8.1 million in Changed Mind returns — addressable through improved product 
content, clearer descriptions, and better imagery — and $2.7 million in Item 
Damaged in Transit returns, directly attributable to underperforming delivery 
partners. Analysis of 180 delivery partners confirms that partners rated below 
3.5 stars generate damage-in-transit rates above 7%, compared to 1.2% for 
top-rated partners. Additionally, 59.8% of return records contain no completion 
date, creating a significant blind spot in returns operations tracking.

Secondary findings compound the primary concerns. Two of 30 marketing campaigns 
— Spring Retargeting Website and Year End Walmart Promo — have negative reported 
ROI, representing $117,645 in combined spend that generated losses on every 
attributed order. Twenty of 30 campaigns overspent their approved budgets by 
a combined $66,044, indicating a budget governance failure rather than a 
marketing performance issue. At the product level, SoundMax 500 ranks fourth 
by revenue but twelfth by profit — a Revenue Illusion driven by 68% average 
discount depth that eliminates the margin the sales volume appears to generate.

---

## Resolution

Three recommendations are prioritised by financial impact and implementation 
speed.

**Recommendation 1 — Implement a category-level discount cap policy (immediate, 
high impact).** Cap all online discounts at 50% as a default ceiling, with 
explicit Category Manager sign-off required for any exception. For Projectors 
and Soundbars specifically, cap discounts at their structural break-even rates — 
29.7% and 33.8% respectively — until pricing is renegotiated with suppliers. 
The What-If analysis in the dashboard quantifies the profit uplift from this 
cap at each threshold level in real time. Estimated annual profit recovery from 
eliminating the 60%+ discount band alone: quantifiable directly from the 
dashboard simulator.

**Recommendation 2 — Close the online channel discount gap through channel-specific 
pricing policy (30-day implementation).** The online channel does not require 
a strategic retreat — it requires the same discount discipline applied to offline. 
Aligning online average discount rates with offline rates on a category-by-category 
basis would recover an estimated $87 million in annual profit at current volumes. 
Begin with Soundbars and Projectors, which are profitable offline and loss-making 
online — the fix is category-level online pricing, not a change to the channel 
strategy.

**Recommendation 3 — Replace the bottom 20% of delivery partners by rating and 
invest in returns content quality (60-day implementation).** Partners rated below 
3.5 stars account for disproportionate damage-in-transit returns. Replacing the 
bottom 20% of the 180-partner network targets the highest-cost, highest-breach 
segment and is estimated to reduce the $2.7 million damage-in-transit refund 
cost by approximately 40%. In parallel, a product content audit targeting the 
top 20 products by Changed Mind return volume — improved images, accurate 
dimensions, clearer use-case descriptions — addresses the $8.1 million 
recoverable Changed Mind return cost at minimal investment.

**Governance recommendation — Immediate.** Pause Spring Retargeting Website and 
Year End Walmart Promo campaigns pending a targeting and pricing review. Implement 
mandatory budget approval controls requiring Finance Director sign-off before 
any campaign can exceed its approved budget. Fix the tracking implementation 
on Independence Day Sales before relaunching — the current clicks-exceed-impressions 
data integrity failure means no ROI figure from that campaign can be trusted.

---

## Data Notes

This analysis is based on 967,268 validated sales transactions following the 
removal of 19,500 duplicate records and 7,732 structurally invalid rows 
(0.78% quarantine rate). An additional 45,395 return records and 30 marketing 
campaign records were cleaned and validated. All financial figures are in USD. 
The full interactive dashboard — with drill-through capability, dynamic 
filters, and a live discount cap simulator — is available as a companion 
to this summary.

---

*Full methodology, SQL cleaning scripts, and data dictionary available on request.*

---
*TechNest Electronics is a fictionalised company name used for portfolio purposes.*
