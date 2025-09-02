-- 1) Modèles jamais vendus mais présents au catalogue

WITH stock AS (
  SELECT
    *,
    CONCAT(model, '_', color, '_', IFNULL(size, 'no-size')) AS product_id
  FROM `circle_ops.circle_stock`
),
sales_agg AS (
  SELECT
    product_id,
    SUM(qty) AS total_sold
  FROM `circle_ops.circle_sales`
  GROUP BY product_id
)
SELECT DISTINCT
  s.model_name
FROM stock s
LEFT JOIN sales_agg sa USING (product_id)
WHERE sa.total_sold IS NULL
ORDER BY s.model_name;


-- 2) Perf mensuelle des livraisons par priorité et transporteur
-- temps moyen, min, max ; nb de produits par colis

WITH parcel_product_merge AS (
  SELECT
    p.parcel_id,
    p.transporter,
    p.priority,
    PARSE_DATE('%B %e, %Y', p.date_purchase) AS date_purchase,
    PARSE_DATE('%B %e, %Y', p.date_shipping) AS date_shipping,
    PARSE_DATE('%B %e, %Y', p.date_delivery) AS date_delivery,
    pp.model_name,
    pp.qty
  FROM `circle_ops.circle_parcel` p
  LEFT JOIN `circle_ops.circle_parcel_product` pp USING (parcel_id)
  WHERE p.date_cancelled IS NULL
),
time_calculation AS (
  SELECT
    *,
    EXTRACT(MONTH FROM date_purchase) AS purchase_month,
    DATE_DIFF(date_delivery, date_purchase, DAY) AS purchase_to_delivery_time
  FROM parcel_product_merge
)
SELECT
  purchase_month,
  CASE
    WHEN priority = 'Low' THEN '3 - Low'
    WHEN priority = 'Medium' THEN '2 - Medium'
    WHEN priority = 'High' THEN '1 - High'
    ELSE priority
  END AS priority_bucket,
  transporter,
  ROUND(AVG(purchase_to_delivery_time), 1) AS avg_delivery_time_days,
  MIN(purchase_to_delivery_time)           AS min_delivery_time_days,
  MAX(purchase_to_delivery_time)           AS max_delivery_time_days,
  COUNT(DISTINCT parcel_id)                AS nb_parcels,
  SUM(qty)                                 AS total_products,
  ROUND(SAFE_DIVIDE(SUM(qty), COUNT(DISTINCT parcel_id)), 1) AS products_per_parcel
FROM time_calculation
GROUP BY purchase_month, priority_bucket, transporter
ORDER BY purchase_month, priority_bucket, transporter;

-- 3) Chiffre d’affaires & intensité quotidienne (par mois)

WITH stock_pid AS (
  SELECT
    price,
    CONCAT(model, '_', color, '_', IFNULL(size, 'no-size')) AS product_id
  FROM `circle_ops.circle_stock`
),
sales_detailed AS (
  SELECT
    s.date_date AS purchase_date,
    EXTRACT(MONTH FROM s.date_date) AS purchase_month,
    s.product_id,
    s.qty,
    sp.price
  FROM `circle_ops.circle_sales` s
  LEFT JOIN stock_pid sp USING (product_id)
)
SELECT
  purchase_month,
  SUM(qty)                              AS total_products_sold,
  SUM(price * qty)                      AS total_revenue,
  ROUND(SAFE_DIVIDE(SUM(price * qty), NULLIF(SUM(qty), 0)), 2) AS average_basket,
  ROUND(SAFE_DIVIDE(SUM(qty), COUNT(DISTINCT purchase_date)), 0) AS avg_products_sold_per_active_day
FROM sales_detailed
GROUP BY purchase_month
ORDER BY purchase_month;
