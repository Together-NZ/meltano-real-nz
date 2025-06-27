{{ config(
    materialized='table',
) }}
with dash_table AS (
SELECT * FROM (
    SELECT SUM(clicks) as clicks,
    SUM(impressions) as impressions,
    SUM(media_cost) as media_cost,
    campaign_name,
    publisher,
    date,
    CASE WHEN 
        REGEXP_CONTAINS(LOWER(campaign_name),'brand')=TRUE
        THEN 'Brand Search' ELSE 'Generic Search'
    END AS search_type
    FROM `real-nz-main.google_ads_search_transformed__tourism.google_ads_search__tourism`
    GROUP BY campaign_name, date,publisher
))
SELECT * EXCEPT(publisher),dc.publisher
FROM dash_table as dt join `together-internal.channel.publisher_channel` as dc
ON lower(dt.publisher) = lower(dc.publisher)