{{ config(
    materialized='table',
) }}   
WITH distinct_ads AS (
        SELECT DISTINCT 
            ad_group_ad_ad_id,
            ARRAY_AGG(DISTINCT IFNULL(ad_group_ad_ad_name, 'Unknown')) AS ad_name,
            ad_group_ad_ad_final_urls AS click_url
        FROM 
            `real-nz-main.google_ads_dv_raw.ads_Ad_1476786244`
        GROUP BY 
            ad_group_ad_ad_id, ad_group_ad_ad_final_urls

    ),
campaign_data AS (
    SELECT 
        campaign_id,
        campaign_name,
        campaign_campaign_budget AS campaign_budget,
        campaign_status,
        _LATEST_DATE
    FROM 
        `real-nz-main.google_ads_dv_raw.ads_Campaign_1476786244`
),
distinct_campaign AS (
    SELECT 
        campaign_id,
        campaign_name,
        campaign_budget,
        ARRAY_AGG(DISTINCT campaign_status) AS campaign_status, -- Aggregate all distinct campaign statuses into an array
        _LATEST_DATE
    FROM 
        campaign_data
    GROUP BY 
        campaign_id, campaign_budget, _LATEST_DATE, campaign_name
),

    distinct_ad_group AS (
        SELECT DISTINCT
            ad_group_id,
            ARRAY_AGG(DISTINCT ad_group_name) AS ad_group_name
        FROM 
            `real-nz-main.google_ads_dv_raw.ads_AdGroup_1476786244`
        GROUP BY 
            ad_group_id
    ),
    result_raw AS (


SELECT  
    ad_stat.ad_group_ad_ad_id AS ad_id, 
    ad.ad_name,  -- Join to bring in the ad name
    ad_group.ad_group_name,
    ad.click_url,
    SUM(ad_stat.metrics_conversions_value) AS revenue, 
    SUM(ad_stat.metrics_conversions) AS total_conversions, 
    SUM(ad_stat.metrics_cost_micros) / 1000000 AS media_cost,
    SUM(ad_stat.metrics_clicks) AS clicks, 
    SUM(ad_stat.metrics_impressions) AS impressions, 
    SUM(ad_stat.metrics_interactions) AS interactions, 
    ad_stat._DATA_DATE as date,
    cam._LATEST_DATE,
    cam.campaign_id AS campaign_external_id,
    cam.campaign_budget AS campaign_budget,
    cam.campaign_name AS campaign_name,
    cam.campaign_status AS campaign_status,
    ROW_NUMBER() OVER (PARTITION BY ad_stat.ad_group_ad_ad_id,_DATA_DATE ORDER BY ad_stat.ad_group_ad_ad_id,_DATA_DATE) AS row_num  -- Use the array to avoid multiple rows
FROM 
    `real-nz-main.google_ads_dv_raw.ads_AdBasicStats_1476786244` AS ad_stat
LEFT JOIN 
    distinct_ads AS ad 
ON 
    ad.ad_group_ad_ad_id = ad_stat.ad_group_ad_ad_id
LEFT JOIN 
    distinct_campaign AS cam
ON 
    cam.campaign_id = ad_stat.campaign_id
LEFT JOIN
    distinct_ad_group AS ad_group
ON 
    ad_group.ad_group_id = ad_stat.ad_group_id

GROUP BY 
    _DATA_DATE, ad_id, ad.ad_name, campaign_external_id, campaign_budget, cam._LATEST_DATE, cam.campaign_status, cam.campaign_name,ad.click_url,ad_group.ad_group_name
    )
SELECT 
    * ,
    'Demand Gen' AS publisher,
    ARRAY(
        SELECT REGEXP_EXTRACT(element, r'PLATFORM_([^_]+)')
        FROM UNNEST(ad_group_name) AS element
        WHERE REGEXP_EXTRACT(element, r'PLATFORM_([^_]+)') IS NOT NULL
    ) AS audience_name,
ARRAY(
    SELECT SPLIT(ad_element, '_')[SAFE_OFFSET(5)]
    FROM UNNEST(ad_name) AS ad_element
    WHERE SPLIT(ad_element, '_')[SAFE_OFFSET(5)] IS NOT NULL
          AND SPLIT(ad_element, '_')[SAFE_OFFSET(5)] <> ''
) AS media_format,
ARRAY(
    SELECT SPLIT(ad_element, '_')[SAFE_OFFSET(5)]
    FROM UNNEST(ad_name) AS ad_element
    WHERE SPLIT(ad_element, '_')[SAFE_OFFSET(5)] IS NOT NULL
          AND SPLIT(ad_element, '_')[SAFE_OFFSET(5)] <> ''
) AS ad_format_detail,
ARRAY(
    SELECT SPLIT(ad_element, '_')[SAFE_OFFSET(6)]
    FROM UNNEST(ad_name) AS ad_element
    WHERE SPLIT(ad_element, '_')[SAFE_OFFSET(6)] IS NOT NULL
          AND SPLIT(ad_element, '_')[SAFE_OFFSET(6)] <> ''
) AS ad_format,
ARRAY(
    SELECT SPLIT(ad_element, '_')[SAFE_OFFSET(7)]
    FROM UNNEST(ad_name) AS ad_element
    WHERE SPLIT(ad_element, '_')[SAFE_OFFSET(7)] IS NOT NULL
          AND SPLIT(ad_element, '_')[SAFE_OFFSET(7)] <> ''
) AS creative_descr,
SPLIT(campaign_name,'_')[SAFE_OFFSET(1)] AS campaign_descr
FROM result_raw WHERE row_num = 1