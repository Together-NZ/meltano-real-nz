{{ config(
    materialized='table',
) }}
WITH dash_table AS (

    SELECT media_cost, impressions, clicks, creative_name, audience_name, ad_format, ad_format_detail, video_completion,video_25_completion,video_50_completion,video_75_completion,video_played AS video_views,
           campaign_name, publisher, campaign_descr, creative_descr, date(date) as date
    FROM `real-nz-main.facebook_transformed__tourism.facebook__tourism`
    UNION ALL
    SELECT media_cost, impressions, clicks, creative_name, audience_name, ad_format, ad_format_detail, video_completion,video_25_completion,video_50_completion,video_75_completion,video_25_completion AS video_views,
           campaign_name, publisher, campaign_descr, creative_descr, date(date) as date
    FROM `real-nz-main.dv360_transformed__tourism.dv360_standard__tourism`
    UNION ALL
    select media_cost,impressions, clicks, creative_name, audience_name, ad_format, ad_format_detail, 
        CAST(0 AS INT64) AS video_completion,
        CAST(0 AS INT64) AS video_25_completion,
        CAST(0 AS INT64) AS video_50_completion,
        CAST(0 AS INT64) AS video_75_completion,
        CAST(0 AS INT64) AS video_views,
    campaign_name,  publisher, campaign_descr, creative_descr, date(date) as date,

from `real-nz-main.cm360_transformed__tourism.cm360_direct_buy__tourism`
    UNION ALL
    SELECT media_cost, impressions, clicks, creative_name, audience_name, ad_format, ad_format_detail, video_completion,video_25_completion,video_50_completion,video_75_completion,video_views,
           campaign_name, publisher, campaign_descr, creative_descr, date(date) as date
    FROM `real-nz-main.ttd_transformed__tourism.ttd_transformed__tourism`
    UNION ALL
      SELECT media_cost, impressions, CAST(0 AS INT64) AS clicks, 
           creative_name,   -- Convert array to string
           audience_name AS audience_name, -- Convert array to string
           ad_format AS ad_format,         -- Convert array to string
           ad_format_detail AS ad_format_detail, 
            CAST(0 AS INT64) AS video_completion,
            CAST(0 AS INT64) AS video_25_completion,
            CAST(0 AS INT64) AS video_50_completion,
            CAST(0 AS INT64) AS video_75_completion,
            CAST(0 AS INT64) AS video_views,
           
           campaign_name,publisher, campaign_descr, 
           creative_descr AS creative_descr, -- Convert array to string
           date,
    FROM `real-nz-main.hivestack_transformed__tourism.hivestack__tourism`
    UNION ALL   
    SELECT media_cost, impressions, clicks, 
           ARRAY_TO_STRING(ad_group_name, ', ') AS creative_name,   -- Convert array to string
           ARRAY_TO_STRING(audience_name, ', ') AS audience_name, -- Convert array to string
           ARRAY_TO_STRING(ad_format, ', ') AS ad_format,         -- Convert array to string
           ARRAY_TO_STRING(ad_format_detail, ', ') AS ad_format_detail, 
            CAST(0 AS INT64) AS video_completion,
            CAST(0 AS INT64) AS video_25_completion,
            CAST(0 AS INT64) AS video_50_completion,
            CAST(0 AS INT64) AS video_75_completion,
            CAST(0 AS INT64) AS video_views,
           
           campaign_name,publisher, campaign_descr, 
           ARRAY_TO_STRING(creative_descr, ', ') AS creative_descr,  -- Convert array to string
           date,


    FROM `real-nz-main.google_ads_dv_transformed__realnz.google_ads_dv__realnz`

),
with_channel AS (
SELECT * EXCEPT (publisher,channel), 
dt.publisher,
dc.channel


FROM dash_table as dt join `together-internal.channel.publisher_channel` as dc
ON lower(dt.publisher) = lower(dc.publisher)),
campaign_base AS (
       SELECT *,
              CASE WHEN ARRAY_LENGTH(SPLIT(campaign_name,'_'))>=2 
              THEN SPLIT(campaign_name,'_')[1] 
              ELSE campaign_name
       END as campaign_name_raw
       FROM with_channel

),
campaign_name_selection_duplicate AS (
       SELECT COUNT(*) AS indicator,lower(campaign_name_raw) AS lower_campaign FROM (SELECT DISTINCT campaign_name_raw FROM campaign_base)
       GROUP BY LOWER(campaign_name_raw) HAVING COUNT(*)>1
),
duplicate_raw AS (
       SELECT distinct campaign_name_raw, ROW_NUMBER() OVER (PARTITION BY LOWER(campaign_name_raw) ORDER BY (campaign_name_raw)) as row_number from campaign_base cb join campaign_name_selection_duplicate cd
       ON LOWER(cb.campaign_name_raw) = LOWER(cd.lower_campaign) 
),
deduplicate_raw AS (
       select * from duplicate_raw where row_number = 1
)
SELECT camb.* EXCEPT(campaign_name_raw),
trim(
CASE WHEN 
       lower(camb.campaign_name_raw) = lower(deduplicate_raw.campaign_name_raw) 
       
       THEN deduplicate_raw.campaign_name_raw
       ELSE camb.campaign_name_raw
END )AS campaign_name_selection,
CASE WHEN 
       EXISTS(SELECT 1 FROM UNNEST(SPLIT(creative_name,'_'))  as a
       WHERE lower(a) in UNNEST(ARRAY['aud','disp','native','pdooh','rmdisp','social','vid','vidod','yt']))
       THEN  (SELECT X FROM UNNEST(SPLIT(creative_name,'_') ) as X WHERE lower(X) IN UNNEST(['aud','disp','native','pdooh','rmdisp','social','vid','vidod','yt'])
       LIMIT 1)
       WHEN  EXISTS(SELECT 1 FROM UNNEST(SPLIT(campaign_name,'_'))  as a
       WHERE lower(a) in UNNEST(ARRAY['aud','disp','native','pdooh','rmdisp','social','vid','vidod','yt']))
       THEN  (SELECT X FROM UNNEST(SPLIT(campaign_name,'_') ) as X WHERE lower(X) IN UNNEST(['aud','disp','native','pdooh','rmdisp','social','vid','vidod','yt'])
       LIMIT 1)
       else 'Other'
END as media_format,



 FROM campaign_base camb LEFT JOIN deduplicate_raw ON LOWER(deduplicate_raw.campaign_name_raw) = LOWER(camb.campaign_name_raw)

