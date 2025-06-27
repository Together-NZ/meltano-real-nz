{{ config(
    materialized='table',
) }}
WITH ad_campaign AS (SELECT DISTINCT 
JSON_VALUE(data,'$.ad_id') as ad_id,
JSON_VALUE(data,'$.ad_name') as ad_name,
JSON_VALUE(data,'$.ad_text') as ad_text,
JSON_VALUE(data,'$.campaign_name') as campaign_name,
JSON_VALUE(data,'$.adgroup_name') as adgroup_name
FROM `real-nz-main.tiktok_raw__mountain.ads` ),
ad_data AS (
  SELECT 
    SAFE_CAST(JSON_VALUE(data, '$.ad_id') AS INT64) AS ad_id,
    SAFE_CAST(JSON_VALUE(data,'$.spend') AS FLOAT64) AS media_cost,
    SAFE_CAST(JSON_VALUE(data, '$.impressions') AS INT64) AS impressions,
    SAFE_CAST(JSON_VALUE(data, '$.clicks') AS INT64) AS clicks,
    JSON_VALUE(data, '$.stat_time_day') AS date,
    ROW_NUMBER() OVER (PARTITION BY SAFE_CAST(JSON_VALUE(data, '$.ad_id') AS INT64),JSON_VALUE(data, '$.stat_time_day')) as row_num
  FROM `real-nz-main.tiktok_raw__mountain.ads_basic_data_metrics_by_day`
),
deduplicate_ad as (
  select * from ad_data where row_num = 1
),
ad_video AS (
  SELECT 
    SAFE_CAST(JSON_VALUE(data, '$.ad_id') AS INT64) AS ad_id,
    SAFE_CAST(JSON_VALUE(data, '$.video_views_p25') AS INT64) AS video_25_completion,   
    SAFE_CAST(JSON_VALUE(data, '$.video_views_p50') AS INT64) AS video_50_completion,
    SAFE_CAST(JSON_VALUE(data, '$.video_views_p75') AS INT64) AS video_75_completion,
    SAFE_CAST(JSON_VALUE(data, '$.video_views_p100') AS INT64) AS video_100_completion,
    SAFE_CAST(JSON_VALUE(data, '$.video_play_actions') AS INT64) AS video_play,
    SAFE_CAST(JSON_VALUE(data, "$.video_watched_2s") AS INT64) AS video_views,
    JSON_VALUE(data, '$.stat_time_day') AS date,
    ROW_NUMBER() OVER (PARTITION BY SAFE_CAST(JSON_VALUE(data, '$.ad_id') AS INT64),JSON_VALUE(data, '$.stat_time_day')) as row_num
  FROM `real-nz-main.tiktok_raw__mountain.ads_video_play_metrics_by_day`
),
deduplicate_ad_video as (
  select * from ad_video where row_num = 1
),
ad_stat_id AS (
SELECT 
  SUM(ad.clicks) AS clicks,
  SUM(ad.media_cost) as media_cost,
  SUM(ad.impressions) AS impressions,
  SUM(ad_v.video_25_completion) as video_25_completion,
  SUM(ad_v.video_50_completion) as video_50_completion,
  SUM(ad_v.video_75_completion) as video_75_completion,
  SUM(ad_v.video_100_completion) as video_100_completion,
  SUM(ad_v.video_play) as video_play,
  SUM(ad_v.video_views) as video_view,
  ad.ad_id as ad_id,
  ad.date
FROM deduplicate_ad as ad JOIN deduplicate_ad_video as ad_v on ad.ad_id = ad_v.ad_id 
AND ad.date = ad_v.date
GROUP BY date, ad_id),
final as (
SELECT ad_stat_id.* EXCEPT(ad_id),
ad_campaign.* FROM ad_stat_id LEFT JOIN ad_campaign ON SAFE_CAST(ad_stat_id.ad_id AS INT64) = SAFE_CAST(ad_campaign.ad_id AS INT64)
)
SELECT * EXCEPT(date,ad_name), DATE(PARSE_DATETIME('%F %H:%M:%S',date)) AS date,
ad_name as creative_name,
    'Tiktok' AS publisher,
    REGEXP_EXTRACT(adgroup_name, r'PLATFORM_([^_]+)') AS audience_name,
    CASE 
        WHEN SPLIT (campaign_name,'_')[OFFSET(3)] LIKE '%SOCIAL%'
        AND (
            lower(ad_name) LIKE '%vid%'
            OR lower(campaign_name) LIKE '%vid%'
            OR lower(adgroup_name) LIKE '%vid%'
        ) THEN 'Social Video'
        WHEN SPLIT (campaign_name,'_')[OFFSET(3)] LIKE '%SOCIAL%'
        AND (
            lower(ad_name) NOT LIKE '%vid%'
            AND lower(campaign_name) NOT LIKE '%vid%'
            AND lower(adgroup_name) NOT LIKE '%vid%'
        )
        THEN 'Social Display'
        ELSE 'Other'
    END AS media_format,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name,'_'))>=8 THEN SPLIT(ad_name, '_')[OFFSET(5)] ELSE 'Other' END AS ad_format_detail,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name,'_'))>=8 THEN SPLIT(ad_name, '_')[OFFSET(6)] ELSE 'Other' END AS ad_format,
    CASE WHEN ARRAY_LENGTH(SPLIT(ad_name,'_'))>=8 THEN SPLIT(ad_name, '_')[OFFSET(7)] ELSE 'Other' END  AS creative_descr,
    SPLIT(campaign_name,'_')[OFFSET(1)] AS campaign_descr
FROM 
    final

