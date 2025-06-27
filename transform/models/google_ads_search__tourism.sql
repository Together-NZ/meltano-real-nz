{{ config(
    materialized='table',
) }}

  WITH  
  campaign_data AS (
    SELECT 
        campaign_id,
        campaign_name,
        campaign_campaign_budget AS campaign_budget,
        campaign_status,
        _LATEST_DATE
    
    FROM 
        `together-internal.google_ads_data_transfer.ads_Campaign_6544860891`
    where customer_id = 5773966980
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
  result_data AS (


SELECT  

    --SUM(ad_stat.metrics_conversions_value) AS revenue, 
    SUM(ad_stat.metrics_conversions) AS total_conversions, 
    SUM(ad_stat.metrics_cost_micros) / 1000000 AS media_cost,
    SUM(ad_stat.metrics_clicks) AS clicks, 
    SUM(ad_stat.metrics_impressions) AS impressions, 
    SUM(ad_stat.metrics_interactions) AS interactions, 
    ad_stat._DATA_DATE AS date,
    cam._LATEST_DATE,
    cam.campaign_id AS campaign_id,
    cam.campaign_budget AS campaign_budget,
    cam.campaign_name AS campaign_name,
    'Google Ads Search' AS publisher,
    cam.campaign_status AS campaign_status,
    ROW_NUMBER() OVER (PARTITION BY _DATA_DATE, cam.campaign_id ORDER BY _DATA_DATE DESC) AS row_number
FROM 
    `together-internal.google_ads_data_transfer.ads_CampaignStats_6544860891` AS ad_stat
LEFT JOIN 
    distinct_campaign AS cam
ON 
    cam.campaign_id = ad_stat.campaign_id
where customer_id = 5773966980
GROUP BY 
    _DATA_DATE,  campaign_id, campaign_budget, cam._LATEST_DATE, cam.campaign_status, cam.campaign_name
    )
SELECT * FROM result_data where row_number = 1