-- =====================================================================
-- AtliQ Sales & Finance Analytics — SQL
-- Gross-to-net sales pipeline + business question queries
-- MySQL | Codebasics Data Analytics Bootcamp
-- =====================================================================

-- ---------------------------------------------------------------------
-- PART 1: Croma India — detailed account report (FY2021)
-- ---------------------------------------------------------------------

-- Gross price total per product, per month, for Croma (Q1 FY2021)
SELECT
    m.date, m.product_code,
    p.product, p.variant, m.sold_quantity, ROUND(g.gross_price, 2),
    ROUND(g.gross_price, 2) * m.sold_quantity AS gross_price_total
FROM fact_sales_monthly AS m
JOIN dim_product AS p
    ON p.product_code = m.product_code
JOIN fact_gross_price AS g
    ON g.product_code = m.product_code
   AND g.fiscal_year = get_fiscal_year(m.date)
WHERE m.customer_code = 90002002
  AND get_fiscal_year(m.date) = 2021
  AND get_fiscal_quarter(m.date) = 'Q1'
ORDER BY m.date ASC;

-- Croma India's FY2021 gross sales total, by fiscal year
SELECT
    g.fiscal_year,
    ROUND(SUM(g.gross_price * m.sold_quantity), 2) AS gross_price_total
FROM fact_sales_monthly AS m
JOIN fact_gross_price AS g
    ON g.product_code = m.product_code
   AND g.fiscal_year = get_fiscal_year(m.date)
WHERE m.customer_code = 90002002
GROUP BY g.fiscal_year
ORDER BY g.fiscal_year ASC;

-- Croma India — full detailed report with pre-invoice discount included
SELECT
    m.date,
    m.product_code,
    p.product,
    p.variant,
    m.sold_quantity,
    g.gross_price AS gross_price_per_item,
    ROUND(m.sold_quantity * g.gross_price, 2) AS gross_price_total,
    pre.pre_invoice_discount_pct
FROM fact_sales_monthly m
JOIN dim_product p
    ON m.product_code = p.product_code
JOIN fact_gross_price g
    ON g.fiscal_year = get_fiscal_year(m.date)
   AND g.product_code = m.product_code
JOIN fact_pre_invoice_deductions AS pre
    ON pre.customer_code = m.customer_code
   AND pre.fiscal_year = get_fiscal_year(m.date)
WHERE m.customer_code = 90002002
  AND get_fiscal_year(m.date) = 2021
LIMIT 1000000;

-- ---------------------------------------------------------------------
-- PART 2: Gross-to-net sales pipeline — all customers, FY2021
-- ---------------------------------------------------------------------

-- Step A: gross sales + pre-invoice discount, joined via dim_date
WITH CTE1 AS (
    SELECT
        m.date,
        m.product_code,
        p.product,
        p.variant,
        m.sold_quantity,
        g.gross_price AS gross_price_per_item,
        ROUND(m.sold_quantity * g.gross_price, 2) AS gross_price_total,
        pre.pre_invoice_discount_pct
    FROM fact_sales_monthly m
    JOIN dim_product p
        ON m.product_code = p.product_code
    JOIN dim_date dt
        ON dt.calendar_date = m.date
    JOIN fact_gross_price g
        ON g.fiscal_year = dt.fiscal_year
       AND g.product_code = m.product_code
    JOIN fact_pre_invoice_deductions AS pre
        ON pre.customer_code = m.customer_code
       AND pre.fiscal_year = dt.fiscal_year
    WHERE dt.fiscal_year = 2021
)
-- Step B: apply pre-invoice discount to get net invoice sales
SELECT *,
    ROUND((gross_price_total - (gross_price_total * pre_invoice_discount_pct)), 2) AS net_invoice_sale
FROM CTE1;

-- Step C: apply post-invoice deductions to reach true net sales
-- (built on top of the sales_preinv_discount / sales_postinv_discount views)
SELECT
    *,
    ROUND(gross_price_total * (1 - pre_invoice_discount_pct), 2) AS net_invoice_sale,
    (po.discounts_pct + po.other_deductions_pct) AS post_invoice_discount_pct
FROM sales_preinv_discount AS s
JOIN fact_post_invoice_deductions AS po
    ON s.date = po.date
   AND s.product_code = po.product_code
   AND s.customer_code = po.customer_code;

SELECT
    *,
    ROUND(net_invoice_sales * (1 - post_invoice_discount_pct), 2) AS net_sales
FROM sales_postinv_discount;

-- ---------------------------------------------------------------------
-- PART 3: Business questions — markets, customers, products (FY2021)
-- ---------------------------------------------------------------------

-- Top 5 markets by net sales ($M)
SELECT
    market,
    ROUND((SUM(net_sales) / 1000000), 2) AS net_sales_mln
FROM net_sales
WHERE fiscal_year = 2021
GROUP BY market
ORDER BY net_sales_mln DESC
LIMIT 5;

-- Net sales by customer ($M)
SELECT
    c.customer,
    ROUND((SUM(net_sales) / 1000000), 2) AS net_sales_mln
FROM net_sales AS ns
JOIN dim_customer AS c
    ON c.customer_code = ns.customer_code
WHERE fiscal_year = 2021
GROUP BY c.customer
ORDER BY net_sales_mln DESC;

-- Net sales % share — global, by customer
WITH CTE1 AS (
    SELECT
        c.customer,
        ROUND((SUM(net_sales) / 1000000), 2) AS net_sales_mln
    FROM net_sales AS ns
    JOIN dim_customer AS c
        ON c.customer_code = ns.customer_code
    WHERE fiscal_year = 2021
    GROUP BY c.customer
)
SELECT
    *,
    net_sales_mln / (SUM(net_sales_mln) OVER ()) * 100 AS global_share_pct
FROM CTE1
ORDER BY net_sales_mln DESC;

-- Net sales % share — by region
WITH CTE1 AS (
    SELECT
        c.customer,
        c.region,
        ROUND((SUM(net_sales) / 1000000), 2) AS net_sales_mln
    FROM net_sales AS ns
    JOIN dim_customer AS c
        ON c.customer_code = ns.customer_code
    WHERE fiscal_year = 2021
    GROUP BY c.customer, c.region
)
SELECT
    *,
    net_sales_mln / (SUM(net_sales_mln) OVER (PARTITION BY region)) * 100 AS region_share_pct
FROM CTE1
ORDER BY region, net_sales_mln DESC;

-- Top 3 products in each division, by quantity sold
WITH CTE1 AS (
    SELECT
        p.division,
        p.product,
        SUM(m.sold_quantity) AS total_qty
    FROM fact_sales_monthly m
    JOIN dim_product p
        ON p.product_code = m.product_code
    WHERE m.fiscal_year = 2021
    GROUP BY p.division, p.product
),
CTE2 AS (
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY division ORDER BY total_qty DESC) AS drnk
    FROM CTE1
)
SELECT *
FROM CTE2
WHERE drnk <= 3;
