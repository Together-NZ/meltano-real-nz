{{ config(
    materialized='table',
) }}

WITH ranked_data AS (
    SELECT
        JSON_VALUE(data, '$.account_currency') AS account_currency,
        JSON_VALUE(data, '$.account_id') AS account_id,
        JSON_VALUE(data, '$.account_name') AS account_name,
        JSON_VALUE(data, '$.ad_id') AS ad_id,
        JSON_VALUE(data, '$.ad_name') AS ad_name,
        JSON_VALUE(data, '$.adset_id') AS adset_id,
        JSON_VALUE(data, '$.adset_name') AS adset_name,
        JSON_VALUE(data, '$.campaign_id') AS campaign_id,
        JSON_VALUE(data, '$.campaign_name') AS campaign_name,
        JSON_EXTRACT_ARRAY(data, '$.conversions') AS conversion_array,
        SAFE_CAST(JSON_VALUE(data, '$.clicks') AS INT64) AS clicks, 
        SAFE_CAST(JSON_VALUE(data, '$.impressions') AS INT64) AS impressions, 
        JSON_VALUE(data, '$.ctr') AS ctr,
        SAFE_CAST(JSON_VALUE(data, '$.spend') AS FLOAT64) AS spend,
        JSON_VALUE(data, '$.date_start') AS date_start,
        JSON_VALUE(data, '$.date_stop') AS date_stop,
        JSON_EXTRACT(data, '$.video_p25_watched_actions') AS video_p25_actions,
        JSON_EXTRACT(data, '$.video_p50_watched_actions') AS video_p50_actions,
        JSON_EXTRACT(data, '$.video_p75_watched_actions') AS video_p75_actions,
        JSON_EXTRACT(data, '$.video_p100_watched_actions') AS video_p100_actions,
        JSON_EXTRACT(data, '$.video_play_actions') AS video_play_actions_array,
        JSON_EXTRACT(data, '$.actions') AS video_view_actions_array,
        JSON_EXTRACT(data, '$.actions') AS actions,
        ROW_NUMBER() OVER (
            PARTITION BY 
                JSON_VALUE(data, '$.account_id'),
                JSON_VALUE(data, '$.ad_id'),
                JSON_VALUE(data, '$.date_start')
            ORDER BY 
                _sdc_extracted_at DESC
        ) AS row_number
    FROM
        `real-nz-main.facebook_raw__tourism.ads_insights_action_video_type`
),
deduplicated_data AS (
    SELECT *
    FROM ranked_data
    WHERE row_number = 1
),
conversion_array AS (
    SELECT conversion_array, ad_id FROM deduplicated_data
),
flattened_video_actions AS (
    SELECT
        date_start,
        ad_id,
        ad_name,
        adset_id,
        adset_name,
        clicks,
        spend,
        campaign_name,
        campaign_id,
        impressions,
        actions,
        JSON_EXTRACT_ARRAY(video_play_actions_array) AS video_play_array,
        JSON_EXTRACT_ARRAY(video_p25_actions) AS video_p25_array,
        JSON_EXTRACT_ARRAY(video_p50_actions) AS video_p50_array,
        JSON_EXTRACT_ARRAY(video_p75_actions) AS video_p75_array,
        JSON_EXTRACT_ARRAY(deduplicated_data.video_p100_actions) AS video_p100_array
    FROM deduplicated_data
),
parsed_video_actions AS (
    SELECT
        date_start,
        ad_id,
        ad_name,
        adset_id,
        adset_name,
        spend,
        clicks,
        campaign_name,
        campaign_id,
        impressions,
        JSON_VALUE(
            ARRAY(
                SELECT JSON_EXTRACT_SCALAR(entry, '$.value')
                FROM UNNEST(JSON_EXTRACT_ARRAY(actions)) AS entry
                WHERE JSON_VALUE(entry, '$.action_type') = 'post'
            )[SAFE_OFFSET(0)]
        ) AS post_share,
        JSON_VALUE(
            ARRAY(
                SELECT JSON_EXTRACT_SCALAR(entry, '$.value')
                FROM UNNEST(JSON_EXTRACT_ARRAY(actions)) AS entry
                WHERE JSON_VALUE(entry, '$.action_type') = 'post_reaction'
            )[SAFE_OFFSET(0)]
        ) AS post_reaction_value,
        JSON_VALUE(
            ARRAY(
                SELECT JSON_EXTRACT_SCALAR(entry, '$.value')
                FROM UNNEST(JSON_EXTRACT_ARRAY(actions)) AS entry
                WHERE JSON_VALUE(entry, '$.action_type') = 'comment'
            )[SAFE_OFFSET(0)]
        ) AS comments,
        JSON_VALUE(
            ARRAY(
                SELECT JSON_EXTRACT_SCALAR(entry, '$.value')
                FROM UNNEST(JSON_EXTRACT_ARRAY(actions)) AS entry
                WHERE JSON_VALUE(entry, '$.action_type') = 'like'
            )[SAFE_OFFSET(0)]
        ) AS likes,
        JSON_VALUE(
            ARRAY(
                SELECT JSON_EXTRACT_SCALAR(entry, '$.value')
                FROM UNNEST(JSON_EXTRACT_ARRAY(actions)) AS entry
                WHERE JSON_VALUE(entry, '$.action_type') = 'post_engagement'
            )[SAFE_OFFSET(0)]
        ) AS post_reaction_engagement,
        JSON_VALUE(
            ARRAY(
                SELECT JSON_EXTRACT_SCALAR(entry, '$.value')
                FROM UNNEST(JSON_EXTRACT_ARRAY(actions)) AS entry
                WHERE JSON_VALUE(entry, '$.action_type') = 'link_click'
            )[SAFE_OFFSET(0)]
        ) AS page_engagement,
        CAST(
            JSON_VALUE(
                video_play_array[0],
                '$.value'
            ) AS INT64
        ) AS last_video_played,
        video_play_array,
        CAST(
            JSON_VALUE(
                video_p25_array[OFFSET(ARRAY_LENGTH(video_p25_array) - 1)],
                '$.value'
            ) AS INT64
        ) AS last_video_p25,
        CAST(
            JSON_VALUE(
                video_p50_array[OFFSET(ARRAY_LENGTH(video_p50_array) - 1)],
                '$.value'
            ) AS INT64
        ) AS last_video_p50,
        CAST(
            JSON_VALUE(
                video_p75_array[OFFSET(ARRAY_LENGTH(video_p75_array) - 1)],
                '$.value'
            ) AS INT64
        ) AS last_video_p75,
        CAST(
            JSON_VALUE(
                video_p100_array[OFFSET(ARRAY_LENGTH(video_p100_array) - 1)],
                '$.value'
            ) AS INT64
        ) AS last_video_p100
    FROM flattened_video_actions
),
summed_data AS (
    SELECT
        date_start,
        ad_id,
        ad_name,
        adset_id,
        adset_name,
        campaign_name,
        campaign_id,
        SUM(SAFE_CAST(post_share AS INT64)) AS shares,
        SUM(SAFE_CAST(likes AS INT64)) AS likes,
        SUM(SAFE_CAST(comments AS INT64)) AS comments,
        SUM(SAFE_CAST(clicks AS INT64)) AS clicks,
        SUM(SAFE_CAST(impressions AS INT64)) AS impressions,
        SUM(SAFE_CAST(post_reaction_value AS INT64)) AS post,
        SUM(SAFE_CAST(page_engagement AS INT64)) AS page_engagement,
        SUM(SAFE_CAST(post_reaction_engagement AS INT64)) AS engagement,
        SUM(spend) AS total_spend,
        SUM(last_video_played) AS total_video_played,
        SUM(last_video_p25) AS total_video_p25,
        SUM(last_video_p50) AS total_video_p50,
        SUM(last_video_p75) AS total_video_p75,
        SUM(last_video_p100) AS total_video_p100
    FROM parsed_video_actions
    GROUP BY date_start, ad_id, ad_name, campaign_id, campaign_name, adset_id, adset_name
),
campaign_data AS (
    SELECT DISTINCT
        JSON_VALUE(data, '$.id') AS campaign_id,
        JSON_VALUE(data, '$.status') AS campaign_status,
        JSON_VALUE(data, '$.objective') AS campaign_objective,
        JSON_VALUE(data, '$.start_time') AS start_time,
        JSON_VALUE(data, '$.stop_time') AS stop_time
    FROM `real-nz-main.facebook_raw__tourism.campaigns`
),
deduplicated_campaign_data AS (
    SELECT
        campaign_id,
        campaign_status,
        campaign_objective,
        start_time,
        stop_time,
        ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY start_time DESC) AS row_num
    FROM campaign_data
),
filtered_campaign_data AS (
    SELECT
        campaign_id,
        campaign_status,
        campaign_objective,
        start_time,
        stop_time
    FROM deduplicated_campaign_data
    WHERE row_num = 1
),
interest_data AS (
    SELECT
        JSON_VALUE(data, '$.id') AS ad_id,
        IFNULL(JSON_EXTRACT_ARRAY(JSON_EXTRACT(data, '$.targeting.flexible_spec')), []) AS flexible_spec_array,
        JSON_EXTRACT_ARRAY(data, '$.device_platforms') AS device
    FROM `real-nz-main.facebook_raw__tourism.ads`
),
filtered_interest_data AS (
    SELECT
        ad_id,
        STRING_AGG(DISTINCT JSON_VALUE(interest_item, '$.name'), ', ') AS interest_names
    FROM interest_data,
    UNNEST(flexible_spec_array) AS flexible_spec_item,
    UNNEST(IFNULL(JSON_EXTRACT_ARRAY(flexible_spec_item, '$.interests'), [])) AS interest_item
    GROUP BY ad_id
),
device_data AS (
    SELECT 
        JSON_VALUE(data, '$.ad_id') AS ad_id,
        CASE 
            WHEN STARTS_WITH(JSON_VALUE(data, '$.device_platform'), 'mobile') THEN 'mobile'
            ELSE JSON_VALUE(data, '$.device_platform')
        END AS device_platform
    FROM 
        `real-nz-main.facebook_raw__tourism.ads_insights_delivery_device`
),
deduplicated_device_data AS (
    SELECT DISTINCT ad_id, device_platform
    FROM device_data
),
aggregated_device_data AS (
    SELECT
        ad_id,
        ARRAY_AGG(DISTINCT device_platform) AS device_platforms
    FROM deduplicated_device_data
    GROUP BY ad_id
),
deplicate_data AS (
SELECT 
    sd.date_start as date,
    sd.ad_id,
    sd.ad_name,
    i.interest_names,
    sd.adset_id AS media_buy_external_id,
    sd.adset_name AS media_buy_external_name,
    sd.campaign_id,
    sd.campaign_name,
    sd.shares,
    sd.likes,
    sd.comments,
    fcd.campaign_status,
    fcd.campaign_objective,
    fcd.start_time,
    fcd.stop_time,
    sd.total_video_p25 as video_25_completion,
    sd.total_video_p50 as video_50_completion,
    sd.total_video_p75 as video_75_completion, 
    sd.total_video_p100 as video_completion,
    sd.total_video_played as video_played,
    da.device_platforms,
    sd.page_engagement AS clicks,
    sd.engagement AS social_post_engagement,
    sd.impressions,
    sd.post AS delivery_social_post_like,
    sd.total_spend as media_cost,
    row_number() OVER (PARTITION BY sd.date_start, sd.ad_id ,fcd.campaign_id ORDER BY sd.date_start) AS row_number
FROM summed_data sd
LEFT JOIN filtered_campaign_data fcd
    ON fcd.campaign_id = sd.campaign_id
LEFT JOIN filtered_interest_data i
    ON i.ad_id = sd.ad_id
LEFT JOIN aggregated_device_data da
    ON da.ad_id = sd.ad_id

ORDER BY sd.date_start, sd.ad_name
)
SELECT * EXCEPT(ad_name) , ad_name as creative_name ,
'Facebook' AS publisher,
CASE WHEN ARRAY_LENGTH(SPLIT(media_buy_external_name, '_'))>=8 THEN
SPLIT(media_buy_external_name, '_')[OFFSET(7)] 
ELSE NULL
END AS audience_name,
CASE 
WHEN SPLIT(campaign_name,'_')[OFFSET(3)] LIKE '%SOCIAL%' AND (lower(campaign_name) like '%vid%' or lower(ad_name) like '%vid%') THEN 'Social Video'
WHEN SPLIT(campaign_name,'_')[OFFSET(3)] LIKE '%SOCIAL%' AND (lower(campaign_name) not like '%vid%' and lower(ad_name) not like '%vid%')THEN 'Social Display'
else 'Other'
END AS media_format,
SPLIT(ad_name, '_')[OFFSET(5)] AS ad_format_detail,
SPLIT(ad_name, '_')[OFFSET(6)] AS ad_format,
SPLIT(ad_name, '_')[OFFSET(7)] AS creative_descr,
SPLIT(campaign_name,'_')[OFFSET(1)] AS campaign_descr
FROM deplicate_data WHERE row_number = 1