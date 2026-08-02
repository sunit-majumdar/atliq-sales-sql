**AtliQ Sales & Finance Analytics — SQL**

India is AtliQ's largest market by net sales ($210.67M in FY2021), and no single customer dominates the business — even Amazon, the top account, holds only 13.2% of global net sales. That's a healthy customer base, but it also means growth has to come from many relationships, not a few big ones.

A SQL project that builds a complete gross-to-net sales pipeline for AtliQ Hardwares and uses it to answer real business questions: which markets and customers drive revenue, how concentrated is that revenue, and which products lead each division. Built in MySQL as part of the Codebasics Data Analytics Bootcamp. (All figures in USD, millions unless stated otherwise. Fiscal Year 2021 — AtliQ's fiscal year runs September to August.)

**Background & Overview**

AtliQ's product and finance teams needed ad-hoc reports that a static Excel model couldn't easily produce — customer-level sales breakdowns, discount-adjusted net sales, and top-N rankings by product and region. This project builds that reporting layer directly in SQL, starting from raw transactions and working up to executive-level insight.

The work has two parts:

A detailed account report for Croma, a key India retail customer — gross sales, discounts, and net sales at the transaction level.
A gross-to-net sales pipeline for the whole business, used to answer: top markets, customer concentration, and top products by division.

**Data Structure**

The database is a standard star schema for transactional sales data:

Fact table: fact_sales_monthly — one row per product, per customer, per month, with quantity sold.
Dimension tables: dim_customer, dim_product, dim_date — describe who bought what, and when.
Supporting fact tables for each layer of the discount waterfall: fact_gross_price (price per product per fiscal year), fact_pre_invoice_deductions (discounts applied before the invoice), fact_post_invoice_deductions (discounts applied after).

A custom SQL function, get_fiscal_year(), converts a calendar date into AtliQ's fiscal year (which starts in September, not January) — this logic is used throughout instead of the calendar year

**Executive Summary**

Built from raw transactions up, this project produces a full gross-to-net sales waterfall: gross sales → pre-invoice discounts → post-invoice deductions → true net sales. Applied to FY2021, it shows India is AtliQ's largest market at $210.67M in net sales, and the customer base is healthy and diversified — the top account (Amazon) holds only 13.2% of global net sales, meaning no single relationship carries outsized risk. The sections below walk through how the pipeline was built and what it revealed.

**Insights Deep-Dive**

1. Building the gross-to-net pipeline. Raw sales data only shows quantity and gross price — it doesn't reflect what AtliQ actually keeps. The project chains together three views: gross sales (quantity × price), minus pre-invoice discounts (customer-specific, applied before billing), minus post-invoice deductions (discounts and other costs applied after). Only the final net_sales view reflects real revenue — and it's the one used for every business question that follows.

2. India leads, but the market is genuinely diversified. India is the top market in FY2021 at $210.67M in net sales. At the customer level, Amazon leads globally at $109.03M, but that's only 13.2% of total net sales — meaning even the biggest account isn't a single point of failure for the business.

3. One customer's full financial story: Croma, India. Beyond the aggregate view, the project builds a complete transaction-level report for Croma — gross sales of $2.32M in FY2021, before any discount is applied. This report exists so a finance stakeholder can trace exactly how gross sales become net sales for one account, line by line.

4. Top products by division. Using DENSE_RANK() partitioned by division, the project surfaces the top 3 products in each division by quantity sold — a query the business would reuse every quarter to track which products actually move.

**Recommendation**

Because customer concentration is already healthy (no account above ~13% of net sales), AtliQ doesn't need a de-risking strategy here — it needs a growth and retention strategy for its base. Given India's lead as the top market, and Amazon's disproportionate importance at the account level, AtliQ should track Amazon's net-sales trend specifically (not just gross), since even a small percentage shift there moves the whole India number. The division-level top-N report should be run each quarter to catch emerging product winners before they show up in the annual numbers.

**Caveats & Assumptions**

Fiscal year definitions follow AtliQ's own convention (September–August), not the calendar year — every query uses get_fiscal_year() rather than YEAR() for this reason.
Net sales figures depend on both pre- and post-invoice deduction data being complete; any gaps in the deductions tables would understate the discount and overstate net sales.
The Croma report and the top-N by division report use different fiscal-year join methods (function-based vs. a joined dim_date.fiscal_year column) — the latter was adopted partway through as a performance improvement over repeatedly calling the function in a join.
Figures are for FY2021 only and would shift as new data is loaded.

**Tools & Skills**

MySQL · joins (INNER, multi-table) · user-defined functions · views (chained, multi-layer) · CTEs · window functions (SUM() OVER, PARTITION BY, DENSE_RANK()) · gross-to-net revenue modeling · top-N and concentration analysis

**Screenshots**

Query output — gross-to-net waterfall for Croma Show Image

Query output — top markets and customer concentration, FY2021 Show Image

Query output — top products by division Show Image

Data is from a simulated but realistic company (AtliQ Hardwares).
