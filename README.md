# Test Publicis

## 3. Analyse Descriptive
### 1. Calculer l'attribution selon le modèle last-touch : au global, en mobile et en desktop

Pour les besoins du test, les données ont été insérées dans une table GCP afin que des requêtes SQL puissent être effectuées. 

#### Postulats
- Je pars du principe qu'un parcours converti est représenté par la triple combinaison `visitor_id`, `order_id`, et `date`. Même si dans le dataset partagé, l'indicateur `date` se suffit à lui seul.
- En analysant le dataset, seuls les parcours convertis sont remontés (le champ `date` réprésentant la date d'achat est mentionné sur toutes les lignes du ds.)

```
with last_touch_attribution as (
select case when device in ('web','tablet') then 'desktop' else device end as device,channel,count(*) as lt_att
from p-assessment.id001.logs_extract
where timestamp = date
group by 1,2
)
,
totals as (
  select sum(lt_att) as total_count
  from last_touch_attribution
)

select channel,
  desktop,
  mobile,
round((desktop / total_count)*100) as desktop_pct,
round((mobile / total_count)*100) as mobile_pct,
round((desktop+mobile)/total_count *100) as global_pct
  from(
select *
from last_touch_attribution
pivot (
  sum(lt_att)
  for device in ('desktop','mobile'))
  )tab
  cross join totals
order by 6 desc
```

Résultat de la requête :

|channel|	desktop|	mobile|	desktop_pct|mobile_pct|	global_pct|
| --- | --- | --- |--- |--- |--- |
|SEO|	2658|	2824|	19.0|	20.0|	39.0|
|DIRECT_ACCESS|	2089|	2388|	15.0|	17.0|	32.0|
|SEA_Google_M|	791|	503|	6.0|	4.0|	9.0|
|REFERRAL|	588|	305|	4.0|	2.0|	6.0|
|AD_EXCHANGE_appnexus|	574|	292|	4.0|	2.0|	6.0|
|AFFILIATION|	219|	81|	2.0|	1.0|	2.0|
|email_auto|	171|	266|	1.0|	2.0|	3.0|
  
On peut en déduire qu'en utilisant le modèle d'attribution last-touch, la majorité des conversions ont été faites sur les canaux SEO et DIRECT ACCESS, représentant en cumulé __71%__ des conversions. Des mesures d'optimisation des campagnes marketing peuvent être recommandées sur ces leviers précis. En revanche, aucune différence significative observée en faisant la distinction entre les devices (mobile vs. desktop).
  
### 2.1 Calculer pour les parcours mono et multileviers :
#### 2.1.1 pourcentage de conversion mono levier & multi leviers

```
select round(sum(case when cnt_channels > 1 then 1 else 0 end) / count(*) *100) as conversion_multilev,
round(sum(case when cnt_channels = 1 then 1 else 0 end) / count(*) *100) as conversion_mono_lev,
count(*) as total_parcours

from (

select a.*
,b.cnt_channels
from `p-assessment.id001.logs_extract` a
inner join ( 
select visitor_id,
  order_id,
  date,
  count(distinct channel) as cnt_channels
from `p-assessment.id001.logs_extract` 
group by 1,2,3 
) b on a.visitor_id = b.visitor_id and a.order_id = b.order_id and a.date = b.date
where a.timestamp = b.date
)tab
```
Résultat de la requête :

| conversion_multilev | conversion_mono_lev | total_parcours |
| --- | --- | --- |
| 37.0 | 63.0 | 14021 |

Sur __14 021 parcours__, __37%__ sont des parcours multi leviers, __63%__ sont des parcours mono levier.

#### 2.1.2 nombre médian / moyen de touches avant la conversion

```
SELECT round(avg(nb_touches_par_parcours)) as nb_moy_touches
FROM(
  SELECT visitor_id,order_id,date, max(rnk) as nb_touches_par_parcours
  FROM (
    SELECT a.*,
    ROW_NUMBER() OVER (PARTITION BY visitor_id, order_id, date order by timestamp desc) as rnk
    FROM `p-assessment.id001.logs_extract` a
  --  WHERE coalesce(interaction,'') = 'CLICK'
  ) tab
  GROUP BY 1,2,3
) tab1
```
Résultat de la requête :
| nb_moy_touches |
| --- |
| 4.0 |

Il faut en moyenne __4 touches__ avant une conversion.

#### 2.1.3 nombre moyenne de jours avant la conversion

```
select round(avg(datediff)) as nb_moy_j_avt_conversion
from(
  select visitor_id,order_id,date, date_diff(tab.max_date, tab.min_date, day)+1 as datediff
  from(

    select a.*,
    min(date(timestamp)) over (partition by visitor_id,order_id,date) as min_date,
    max(date(date)) over (partition by visitor_id,order_id,date) as max_date
    from `p-assessment.id001.logs_extract` a

  )tab
  group by 1,2,3,4
)tab1
```
Résultat requête :
| nb_moy_j_avt_conversion |
| --- |
| 6.0 |

Il faut en moyenne __6 jours__ pour qu'une conversion ait lieu. 

### 3. Calculer les Top 10 /15 combinaisons des leviers : synergies remarquables : mobile vs desktop

```
with subquery as (
    SELECT visitor_id, 
        order_id,
        date,
        case when device in ('web','tablet') then 'desktop' else device end as device, 
        channel, 
        max(timestamp) as timestamp
    FROM `p-assessment.id001.logs_extract`
    GROUP BY 1,2,3,4,5
)

,top_combination as (
select device,channel_combination
,row_number() over (partition by device order by count(*) desc) as top_combi_rnk
from (
  select visitor_id, 
    order_id,
    date,
    device, 
    array_to_string(array_agg(channel order by timestamp), ' > ') as channel_combination
  from subquery
  group by 1,2,3,4
) tab
group by 1,2
)

select t.top_combi_rnk,
channel_combination as desktop,
j.mobile
from top_combination t
inner join (
    select top_combi_rnk,
    channel_combination as mobile
    from top_combination
    where device = 'mobile'
) j on j.top_combi_rnk = t.top_combi_rnk
where device = 'desktop'
order by 1
limit 15
```

Résultat :

|top	|desktop	|mobile|
| --- | --- | --- |
|1|	SEO|	SEO|
|2|	DIRECT_ACCESS|	DIRECT_ACCESS|
|3|	SEA_Google_M|	AD_EXCHANGE_appnexus > SEO|
|4|	AD_EXCHANGE_appnexus|	SEA_Google_M|
|5|	AD_EXCHANGE_appnexus > SEO|	email_auto > DIRECT_ACCESS|
|6|	AD_EXCHANGE_appnexus > DIRECT_ACCESS|	SEO > DIRECT_ACCESS|
|7|	AFFILIATION > REFERRAL|	DIRECT_ACCESS > SEO|
|8|	email_auto > DIRECT_ACCESS|	AD_EXCHANGE_appnexus > DIRECT_ACCESS|
|9|	SEA_Bing_M|	AD_EXCHANGE_appnexus|
|10|	SEO > DIRECT_ACCESS	|email_auto|
|11	|REFERRAL|	SEO > AD_EXCHANGE_appnexus|
|12	|DIRECT_ACCESS > SEO|	DIRECT_ACCESS > email_auto|
|13	|email_auto	|SEO > AD_EXCHANGE_appnexus > DIRECT_ACCESS|
|14|	AFFILIATION|	SEO > email_auto > DIRECT_ACCESS|
|15|	email_auto > SEO|	REFERRAL|

### 4. Question bonus (choix entre data visualisation et/ou machine Learning)
#### 4.1 Data Visualisation : Etablissez un Sunburst permettant de tracer un échantillon de parcours convertis.
Afin de créer un diagramme Sunburst, on doit procéder de la manière suivante :
##### 4.1.1. Reconstition du dataset afin d'obtenir les différents parcours convertis et leurs nombres associés
Il y a eu un parti pris de ne pas représenter un parcours avec les duplications consécutives de clics pour un même levier (`channel`), dû à un défaut de mémoire + des combinaisons > à 54 touchpoints sur le diagramme ce qui rendait ce dernier illisible. Pour ce faire, lorsque plusieurs clics consécutifs sont effectués sur un même levier marketing, celui-ci n'est représenté qu'une seule fois dans le parcours. 

La requête permettant d'extraire ce schéma est le suivant :
```
select full_journey,count(*) as nb_parcours
from(
  select visitor_id
  ,order_id
  ,date
  ,array_to_string(array_agg(channel order by timestamp), '-') as full_journey
  from(
    select tab.*
    from (
      select a.*,
      lag(channel) over (partition by visitor_id, order_id, date order by timestamp) as previous_channel, /* supression unique des doublons consécutifs */
      from p-assessment.id001.logs_extract a
    )tab
    where (channel <> previous_channel or previous_channel is null)
  ) tab1
  group by 1,2,3
) tab2
group by 1
order by 2 desc
```
###### 4.1.2. Extraction des résultats dans un fichier .csv

Le résultat de la requête ci-dessus a été exportée en un [fichier .csv](bquxjob_3d9765be_185c749b3cc.csv).
###### 4.1.3. Construction du diagramme Sunburst
Le Sunburst des parcours convertis a été créé en utilisant la librairie __SunburstR__ disponible dans R Studio, le script permettant de créer le diagramme est disponible [ici](sunburst_chart.R) et le résultat : [ici](test_publicis_sunburst_chart_using_R.html).
<br>
<br>
<img width="542" alt="Capture d’écran 2023-01-19 à 01 13 01" src="https://user-images.githubusercontent.com/86535632/213325552-8f8effb3-064a-4ea6-b5e5-f34e68f7e77e.png">

#### 4.2 Machine Learning
Etablissez un modèle data Driven pour calculer la contribution des différents leviers à la conversion. Expliquer la démarche.
Indication un modèle data Driven permet de prendre en compte l’ensemble des leviers participant à une conversion à l’instar du modèle last touch qui prend en compte que la dernière touche.

J'ai choisi d'utiliser la solution de répartitions des gains de Shapley. Dans la théorie des jeux, la valeur de Shapley est un concept de solution permettant de répartir équitablement les gains et les coûts entre plusieurs acteurs (ici `channel`) travaillant en coalition. Celle-ci s'applique principalement dans les situations où les contributions de chaque acteur sont inégales, mais où ils travaillent en coopération les uns avec les autres pour obtenir un gain (= conversion). Les joueurs ici sont représentés par les canaux markéting (`SEO`, `DIRECT ACCESS` etc..) et chacun d'entre eux peut être considéré comme travaillant en synergie (formation d'une __coalition__) afin de générer des __conversions__. En d'autres termes, cette approche attribue équitablement la contribution de chaque touch point à la conversion.

Ci-dessous, le résultat graphique obtenu en se basant sur les données à disposition, le notebook permettant de calculer la valeur de Shapley est disponible [ici](data-driven_attribution_model_Shapley.ipynb)

![image](https://user-images.githubusercontent.com/86535632/213578591-5ae41062-6050-4f48-a423-42543601f211.png)

