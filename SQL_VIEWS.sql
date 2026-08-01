# Latest NAV for Every Fund
CREATE OR REPLACE VIEW vw_latest_nav AS
WITH latest_nav AS
(
    SELECT
        scheme_code,
        nav,
        nav_date,
        ROW_NUMBER() OVER(
            PARTITION BY scheme_code
            ORDER BY nav_date DESC
        ) AS rn
    FROM fact_nav
)
SELECT
    d.scheme_code,
    d.scheme_name,
    l.nav AS latest_nav,
    l.nav_date
FROM latest_nav l
JOIN dim_fund d
ON l.scheme_code = d.scheme_code
WHERE rn = 1;
SELECT *
FROM vw_latest_nav
LIMIT 1000;
# Monthly Average NAV
CREATE OR REPLACE VIEW vw_monthly_nav AS
SELECT
    scheme_code,
    YEAR(nav_date) AS year,
    MONTH(nav_date) AS month,
    AVG(nav) AS average_nav
FROM fact_nav
GROUP BY
    scheme_code,
    YEAR(nav_date),
    MONTH(nav_date);
SELECT *
FROM vw_monthly_nav
LIMIT 1000;
# Yearly Average NAV
CREATE OR REPLACE VIEW vw_yearly_nav AS
SELECT
    scheme_code,
    YEAR(nav_date) AS year,
    AVG(nav) AS average_nav
FROM fact_nav
GROUP BY
    scheme_code,
    YEAR(nav_date);
SELECT *
FROM vw_yearly_nav
LIMIT 1000;    
# Growth Summary
CREATE OR REPLACE VIEW vw_growth_summary AS
WITH fund_nav AS
(
    SELECT
        scheme_code,
        nav,
        nav_date,
        ROW_NUMBER() OVER(
            PARTITION BY scheme_code
            ORDER BY nav_date
        ) first_row,
        ROW_NUMBER() OVER(
            PARTITION BY scheme_code
            ORDER BY nav_date DESC
        ) last_row
    FROM fact_nav
),
first_nav AS
(
    SELECT
        scheme_code,
        nav first_nav
    FROM fund_nav
    WHERE first_row = 1
),
latest_nav AS
(
    SELECT
        scheme_code,
        nav latest_nav
    FROM fund_nav
    WHERE last_row = 1
)
SELECT
    d.scheme_code,
    d.scheme_name,
    first_nav,
    latest_nav,
    ROUND(
        ((latest_nav - first_nav) / first_nav) * 100,
        2
    ) AS growth_percent
FROM first_nav
JOIN latest_nav
USING(scheme_code)
JOIN dim_fund d
USING(scheme_code);
SELECT *
FROM vw_growth_summary
ORDER BY growth_percent DESC
LIMIT 1000;
# Fund Statistics
CREATE OR REPLACE VIEW vw_fund_statistics AS
SELECT
    d.scheme_code,
    d.scheme_name,
    COUNT(*) AS total_nav_records,
    MIN(nav_date) AS inception_date,
    MAX(nav_date) AS latest_date,
    MIN(nav) AS minimum_nav,
    MAX(nav) AS maximum_nav,
    ROUND(AVG(nav),2) AS average_nav
FROM fact_nav f
JOIN dim_fund d
ON f.scheme_code = d.scheme_code
GROUP BY
    d.scheme_code,
    d.scheme_name;
SELECT *
FROM vw_fund_statistics
LIMIT 1000;
