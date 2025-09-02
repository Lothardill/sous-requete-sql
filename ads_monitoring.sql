- 1) EXPLORATION RAPIDE (optionnel)
-- SELECT * FROM `ads_monitoring.ads_orders` LIMIT 10;
-- SELECT * FROM `ads_monitoring.ads_sessions` LIMIT 10;

-- 1.1 TESTS DE CLE PRIMAIRE (doivent retourner 0 ligne si OK)
-- Orders: PK = orders_id
SELECT
  -- ### Key ###
  orders_id,
  -- ###########
  COUNT(*) AS nb
FROM `ads_monitoring.ads_orders`
GROUP BY orders_id
HAVING nb >= 2
ORDER BY nb DESC;

-- Sessions: PK = session_id
SELECT
  -- ### Key ###
  session_id,
  -- ###########
  COUNT(*) AS nb
FROM `ads_monitoring.ads_sessions`
GROUP BY session_id
HAVING nb >= 2
ORDER BY nb DESC;

-- 2) UNION DES 4 SOURCES PAID EN UNE SEULE TABLE DE CAMPAGNES
--    (date_date, paid_source, campaign_key, campaign_name, cost, impression, click)
CREATE OR REPLACE TABLE `ads_monitoring.ads_campaign` AS
SELECT * FROM `ads_monitoring.ads_adwords`
UNION ALL SELECT * FROM `ads_monitoring.ads_bing`
UNION ALL SELECT * FROM `ads_monitoring.ads_criteo`
UNION ALL SELECT * FROM `ads_monitoring.ads_facebook`;

-- 3) ORDERS x SESSIONS : on ne garde que les commandes traquées (INNER JOIN)
CREATE OR REPLACE TABLE `ads_monitoring.ads_orders_ga` AS
SELECT
  o.date_date,
  -- ### Key ###
  o.orders_id,
  -- ###########
  -- Orders
  o.turnover,
  o.news,
  -- Session
  se.session_id,
  se.campaign_key,
  se.campaign
FROM `ads_monitoring.ads_orders` AS o
INNER JOIN `ads_monitoring.ads_sessions` AS se
USING (session_id);

-- 4) AGREGER LES COMMANDES PAR JOUR & CAMPAGNE (1:1 vs campagnes)
CREATE OR REPLACE TABLE `ads_monitoring.ads_campaign_orders` AS
SELECT
  -- ### Key ###
  date_date,
  campaign_key,
  -- ###########
  COUNT(DISTINCT orders_id) AS nb_transactions,
  SUM(turnover)             AS turnover,
  SUM(news)                 AS news
FROM `ads_monitoring.ads_orders_ga`
GROUP BY date_date, campaign_key;

-- 5) JOIN CAMPAGNES (coûts) x ORDERS AGREGEES (revenus) – garder toutes les campagnes payantes
CREATE OR REPLACE TABLE `ads_monitoring.ads_campaign_join` AS
SELECT
  -- ### Key ###
  c.date_date,
  c.campaign_key,
  -- ###########
  -- Campagnes (paid)
  c.paid_source,
  c.campaign_name,
  c.cost,
  c.click,
  c.impression,
  -- KPIs commandes agrégées (mettre 0 si pas de ventes ce jour/cette campagne)
  IFNULL(o.nb_transactions, 0) AS nb_transactions,
  IFNULL(o.turnover,       0)  AS turnover,
  IFNULL(o.news,           0)  AS news
FROM `ads_monitoring.ads_campaign` AS c
LEFT JOIN `ads_monitoring.ads_campaign_orders` AS o
  ON c.date_date = o.date_date
 AND c.campaign_key = o.campaign_key;

-- 6) AGREGER PAR SOURCE PAYANTE (premier niveau, sans calculer encore les KPIs)
--    (Sous-requête pour calculer ROAS/CAC/CPM/CPC/CTR)
WITH gz_campaign_ps AS (
  SELECT
    -- ### Key ###
    paid_source,
    -- ###########
    -- Orders
    SUM(nb_transactions)            AS nb_transactions,
    SUM(news)                       AS news,
    ROUND(SUM(turnover),   0)       AS turnover,
    -- Paid
    ROUND(SUM(cost),       0)       AS cost,
    ROUND(SUM(click),      0)       AS click,
    ROUND(SUM(impression), 0)       AS impression
  FROM `ads_monitoring.ads_campaign_join`
  GROUP BY paid_source
)
SELECT
  -- ### Key ###
  paid_source,
  -- ###########
  nb_transactions,
  turnover,
  cost,
  click,
  impression,
  -- KPIs
  ROUND(SAFE_DIVIDE(turnover, cost),              2) AS roas,
  ROUND(SAFE_DIVIDE(cost,     news),              2) AS cac_new,
  ROUND(SAFE_DIVIDE(cost,     nb_transactions),   2) AS cac_orders,
  ROUND(SAFE_DIVIDE(cost,     impression) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(cost,     click),             2) AS cpc,
  ROUND(SAFE_DIVIDE(click,    impression) * 100,  2) AS ctr
FROM gz_campaign_ps
ORDER BY paid_source;

-- 7) DECLINAISON MENSUELLE PAR SOURCE (évolution dans le temps)
WITH gz_campaign_ps AS (
  SELECT
    -- ### Key ###
    paid_source,
    EXTRACT(MONTH FROM date_date) AS month,
    -- ###########
    -- Orders
    SUM(nb_transactions)            AS nb_transactions,
    SUM(news)                       AS news,
    ROUND(SUM(turnover),   0)       AS turnover,
    -- Paid
    ROUND(SUM(cost),       0)       AS cost,
    ROUND(SUM(click),      0)       AS click,
    ROUND(SUM(impression), 0)       AS impression
  FROM `ads_monitoring.ads_campaign_join`
  GROUP BY paid_source, month
)
SELECT
  -- ### Key ###
  paid_source,
  month,
  -- ###########
  nb_transactions,
  turnover,
  cost,
  click,
  impression,
  -- KPIs
  ROUND(SAFE_DIVIDE(turnover, cost),              2) AS roas,
  ROUND(SAFE_DIVIDE(cost,     news),              2) AS cac_new,
  ROUND(SAFE_DIVIDE(cost,     nb_transactions),   2) AS cac_orders,
  ROUND(SAFE_DIVIDE(cost,     impression) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(cost,     click),             2) AS cpc,
  ROUND(SAFE_DIVIDE(click,    impression) * 100,  2) AS ctr
FROM gz_campaign_ps
ORDER BY paid_source, month;
