# Sous-requête SQL

Chaque partie correspond à une compétence ou une notion particulière, et contient les fichiers SQL et jeux de données associés.

## Partie 1 – Analyse financière avec sous-requêtes

Objectif : illustrer l’utilisation des sous-requêtes (subqueries) pour éviter la création de tables intermédiaires inutiles.

Fichiers :
- `finance_analysis.sql` : script SQL contenant toutes les requêtes utilisant des sous-requêtes (WITH ... AS) au lieu de tables intermédiaires.
- `1-sales_data.csv`, `1-shipping_data.csv`, `1-marketing_campaigns.csv` : datasets.

## Partie 2 – Analyse média & attribution (ads)

Objectif : transformer et analyser les données publicitaires (AdWords, Bing, Criteo, Facebook) en les reliant aux sessions et commandes pour suivre la performance par source et campagne (ROAS, CAC, CPM, CPC, CTR), avec tests de PK et agrégations mensuelles — le tout sans tables intermédiaires inutiles (CTE / WITH … AS).

Fichiers :
- `media_performance_analysis.sql` : script complet (exploration, tests PK, UNION ALL des campagnes, joins Orders Sessions, agrégations & KPIs par source et par mois).
- `2-ads_monitoring.ads_facebook.csv`, `2-ads_monitoring.ads_criteo.csv`, `2-ads_monitoring.ads_bing.csv` et `2-ads_monitoring.ads_adwords.csv` : datasets complets.
- `2-ads_monitoring.ads_sessions.csv` et `2-ads_monitoring.ads_orders.csv` : datasets limité à 2000 lignes.

⚠️ Les dataset incomplets (>50 Mo) ne sont pas versionné pour des raisons de taille. Ces échantillons sont fourni pour la démonstration, mais toutes les requêtes du script SQL sont applicables à l’intégralité des jeux de données.

## Partie 3 – Analyse média & attribution (ads)

Objectif : analyser les stocks, les ventes et la performance logistique des livraisons pour identifier :
- les modèles présents au catalogue mais jamais vendus,
- les temps moyens, minimum et maximum de livraison par transporteur et priorité,
- les indicateurs de chiffre d’affaires et de volume de ventes par mois.

Fichiers :
- `3-circle_analysis.sql` : script SQL regroupant les requêtes d’exploration et d’analyse (stocks, livraisons, CA).

- `3-circle_ops.circle_stock.csv`, `3-circle_ops.circle_sales.csv`, `3-circle_ops.circle_parcel_product.csv` et `3-circle_ops.circle_parcel.csv` : datasets.
