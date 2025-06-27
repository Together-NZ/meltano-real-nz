-- models/get_yt_ads_data_deduplicated.sql
{{ config(
    materialized='table',
) }}
WITH parsed_data AS (
    SELECT
        -- select the dv360 true view data
        JSON_VALUE(data, "$.Advertiser Currency") AS advertiser_currency,
        JSON_VALUE(data, "$.Clicks") AS clicks,
        JSON_EXTRACT_SCALAR(data, "$['Complete Views (Video)']") AS complete_views_video,
        FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y/%m/%d', JSON_VALUE(data, "$.Date"))) AS date, -- Convert date format
        JSON_EXTRACT_SCALAR(data, "$['First-Quartile Views (Video)']") AS first_quartile_views_video,
        JSON_VALUE(data, "$.Impressions") AS impressions,
        JSON_VALUE(data, "$.Insertion Order") AS campaign_name,
        JSON_VALUE(data, "$.Insertion Order ID") AS campaign_id,
        JSON_VALUE(data, "$.Insertion Order Status") AS campaign_status,
        JSON_VALUE(data, "$.Line Item") AS line_item,
        JSON_VALUE(data, "$.Line Item ID") AS line_item_id,
        JSON_EXTRACT_SCALAR(data, "$['Midpoint Views (Video)']") AS midpoint_views_video,
        JSON_EXTRACT_SCALAR(data, "$['Revenue (Adv Currency)']") AS media_cost,
        JSON_EXTRACT_SCALAR(data, "$['Third-Quartile Views (Video)']") AS third_quartile_views_video,
        JSON_VALUE(data, "$.YouTube Ad") AS youtube_ad,
        JSON_VALUE(data, "$.YouTube Ad Group") AS youtube_ad_group,
        JSON_VALUE(data, "$.YouTube Ad Group ID") AS youtube_ad_group_id,
        ROW_NUMBER() OVER (
            PARTITION BY 
                FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%Y/%m/%d', JSON_VALUE(data, "$.Date"))), -- Use converted date
                JSON_VALUE(data, "$.Insertion Order ID"),
                JSON_VALUE(data, "$.Line Item ID"),
                JSON_VALUE(data, "$.YouTube Ad")
            ORDER BY 
                CAST(JSON_EXTRACT_SCALAR(data, "$['Revenue (Adv Currency)']") AS FLOAT64) DESC -- Keep the record with the highest revenue
        ) AS row_num
    FROM
        `real-nz-main.dv360_raw__tourism.dv360_youtube`
)

SELECT
    advertiser_currency,
    SAFE_CAST(clicks AS INT64) AS clicks,
    SAFE_CAST(complete_views_video AS INT64) AS video_completion,
    date,
    SAFE_CAST(first_quartile_views_video AS INT64) AS video_25_completion,
    safe_cast(impressions AS INT64) AS impressions,
    campaign_name,
    campaign_id,
    campaign_status,
    line_item,
    line_item_id,
    SAFE_CAST(midpoint_views_video AS INT64) AS video_50_completion,
    SAFE_CAST(media_cost AS FLOAT64) AS media_cost,
    SAFE_CAST(third_quartile_views_video AS INT64) AS video_75_completion,
    youtube_ad,
    youtube_ad_group,
    youtube_ad_group_id,
    REGEXP_EXTRACT(line_item, r'PLATFORM_([^_]+)') AS audience_name,
    'Youtube' AS publisher,
    'Youtube Video' AS media_format,
    CASE WHEN ARRAY_LENGTH(SPLIT(youtube_ad,'_')) < 8 THEN 'Other' ELSE SPLIT(youtube_ad,'_')[OFFSET(5)] 
    END AS ad_format_detail,
    CASE WHEN ARRAY_LENGTH(SPLIT(youtube_ad,'_')) < 8 THEN 'Other' ELSE SPLIT(youtube_ad,'_')[OFFSET(7)] 
    END AS creative_descr,
    'No Valid' as ad_format,
    CASE WHEN ARRAY_LENGTH(SPLIT(campaign_name,'_')) <=1 THEN 'Other' ELSE SPLIT(campaign_name,'_')[OFFSET(1)] 
    END AS campaign_descr
FROM
    parsed_data
WHERE
    row_num = 1
