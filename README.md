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
- `1-sales_data.csv`, `1-shipping_data.csv`, `1-marketing_campaigns.csv` : datasets.
2-gwz_adwords.csv

2-gwz_bing.csv

2-gwz_criteo.csv

2-gwz_facebook.csv

2-gwz_orders.csv

2-gwz_sessions.csv
⚠️ Les dataset complets (>50 Mo) n’est pas versionné pour des raisons de taille. Cet échantillon est fourni pour la démonstration, mais toutes les requêtes du script SQL sont applicables à l’intégralité du jeu de données.
