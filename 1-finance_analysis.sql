-- 1) Monitoring finance — jointure ventes / expéditions (en 1 requête via WITH)

-- Construction d'une table temporaire agrégée par commande et date
WITH orders_join AS (
  SELECT
    date_date,
    -- ### Key ###
    orders_id,
    -- ###########
    ROUND(SUM(turnover), 2)                   AS turnover,
    ROUND(SUM(turnover - purchase_cost), 2)   AS margin
  FROM `6-sales_data.csv`
  GROUP BY date_date, orders_id
)

-- Jointure avec les données shipping
SELECT
  o.date_date,
  -- ### Key ###
  o.orders_id,
  -- ###########
  o.turnover,
  o.margin,
  sh.shipping_fee,
  (sh.log_cost + sh.ship_cost)                AS operational_cost
FROM orders_join AS o
LEFT JOIN `6-shipping_data.csv` AS sh
  ON o.orders_id = sh.orders_id;

-- 2) Jointure commandes + campagnes marketing

WITH orders_date AS (
  SELECT
    -- ### Key ###
    date_date,
    -- ###########
    SUM(turnover)         AS turnover,
    SUM(margin)           AS margin,
    SUM(shipping_fee)     AS shipping_fee,
    SUM(operational_cost) AS operational_cost
  FROM orders_join
  GROUP BY date_date
),
campaign_date AS (
  SELECT
    -- ### Key ###
    date_date,
    -- ###########
    SUM(ads_cost) AS ads_cost
  FROM `6-marketing_campaigns.csv`
  GROUP BY date_date
)

SELECT
  -- ### Key ###
  o.date_date,
  -- ###########
  o.turnover,
  o.margin,
  o.shipping_fee,
  o.operational_cost,
  c.ads_cost
FROM orders_date AS o
LEFT JOIN campaign_date AS c
  USING (date_date)
ORDER BY o.date_date DESC;

-- 3) Calculs de marge (margin, margin_percent, margin_level)

WITH margin_table AS (
  SELECT
    -- ### Key ###
    orders_id, products_id,
    -- ###########
    turnover,
    (turnover - purchase_cost) AS margin
  FROM `6-sales_data.csv`
),
margin_percent_table AS (
  SELECT
    -- ### Key ###
    orders_id, products_id,
    -- ###########
    turnover,
    margin,
    ROUND(SAFE_DIVIDE(margin, turnover), 2) AS margin_percent
  FROM margin_table
)
SELECT
  -- ### Key ###
  orders_id, products_id,
  -- ###########
  turnover,
  margin,
  margin_percent,
  CASE
    WHEN margin_percent < 0.05 THEN 'low'
    WHEN margin_percent > 0.40 THEN 'high'
    WHEN margin_percent BETWEEN 0.05 AND 0.40 THEN 'medium'
    ELSE NULL
  END AS margin_level
FROM margin_percent_table;

-- 4) Catégorisation des promotions

WITH promo_table AS (
  SELECT
    -- ### Key ###
    orders_id, products_id,
    -- ###########
    turnover,
    promo_name,
    (turnover_before_promo - turnover) AS promo
  FROM `6-sales_data.csv`
),
promo_percent_table AS (
  SELECT
    -- ### Key ###
    orders_id, products_id,
    -- ###########
    turnover,
    promo_name,
    promo,
    ROUND(SAFE_DIVIDE(promo, turnover), 2) AS promo_percent
  FROM promo_table
)
SELECT
  -- ### Key ###
  orders_id, products_id,
  -- ###########
  turnover,
  promo_name,
  promo,
  promo_percent,
  CASE
    WHEN UPPER(promo_name) LIKE '%DLC%' OR UPPER(promo_name) LIKE '%DLUO%' THEN 'short-lived'
    WHEN promo_percent >= 0.30 THEN 'High promotion'
    WHEN promo_percent < 0.10 THEN 'Low promotion'
    WHEN promo_percent >= 0.10 AND promo_percent < 0.30 THEN 'Medium promotion'
    ELSE NULL
  END AS promo_type
FROM promo_percent_table;
