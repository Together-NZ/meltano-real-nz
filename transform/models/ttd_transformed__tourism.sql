{{ config(
    materialized='table',
) }}
WITH parsed_data AS (
    SELECT
        FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%d/%m/%Y', JSON_VALUE(JSON_EXTRACT(data, "$.Date")))) AS date,
        JSON_VALUE(JSON_EXTRACT(data, "$.Partner ID")) AS partner_id,
        JSON_VALUE(JSON_EXTRACT(data, "$.Advertiser ID")) AS advertiser_id,
        JSON_VALUE(JSON_EXTRACT(data, "$.Campaign ID")) AS campaign_id,
        JSON_VALUE(JSON_EXTRACT(data, "$.Ad Group ID")) AS ad_group_id,
        JSON_VALUE(JSON_EXTRACT(data, "$.Ad Format")) AS ad_format,
        JSON_VALUE(JSON_EXTRACT(data, "$.Creative ID")) AS creative_id,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$.Frequency")) AS FLOAT64) AS frequency,
        JSON_VALUE(JSON_EXTRACT(data, "$.Advertiser")) AS advertiser,
        JSON_VALUE(JSON_EXTRACT(data, "$.Campaign")) AS campaign_name,
        JSON_VALUE(JSON_EXTRACT(data, "$.Ad Group")) AS ad_group,
        JSON_VALUE(JSON_EXTRACT(data, "$.Advertiser Currency Code")) AS advertiser_currency_code,
        JSON_VALUE(JSON_EXTRACT(data, "$.Partner Currency Code")) AS partner_currency_code,
        JSON_VALUE(JSON_EXTRACT(data, "$.Creative")) AS creative,
        JSON_VALUE(JSON_EXTRACT(data, "$.Deal ID")) AS deal_id,
        JSON_VALUE(JSON_EXTRACT(data, "$.Ad Server Name")) AS ad_server_name,
        JSON_VALUE(JSON_EXTRACT(data, "$.Ad Server Creative Placement ID")) AS ad_server_creative_placement_id,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$.Bids")) AS INT64) AS bids,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Total Bid Amount (Adv Currency)']")), ',', '.') AS FLOAT64) AS total_bid_amount_adv_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Total Bid Amount (Partner Currency)']")), ',', '.') AS FLOAT64) AS total_bid_amount_partner_currency,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$.Impressions")) AS INT64) AS impressions,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$.Clicks")) AS INT64) AS clicks,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['TTD Cost (Adv Currency)']")), ',', '.') AS FLOAT64) AS ttd_cost_adv_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['TTD Cost (Partner Currency)']")), ',', '.') AS FLOAT64) AS ttd_cost_partner_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Partner Cost (Adv Currency)']")), ',', '.') AS FLOAT64) AS partner_cost_adv_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Partner Cost (Partner Currency)']")), ',', '.') AS FLOAT64) AS partner_cost_partner_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Advertiser Cost (Adv Currency)']")), ',', '.') AS FLOAT64) AS advertiser_cost_adv_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Advertiser Cost (Partner Currency)']")), ',', '.') AS FLOAT64) AS advertiser_cost_partner_currency,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Player 25% Complete']")), ',', '.') AS FLOAT64) AS player_25_complete,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Player 50% Complete']")), ',', '.') AS FLOAT64) AS player_50_complete,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Player 75% Complete']")), ',', '.') AS FLOAT64) AS player_75_complete,
        CAST(REPLACE(JSON_VALUE(JSON_EXTRACT(data, "$['Player 100% Complete']")), ',', '.') AS FLOAT64) AS player_100_complete,

        -- Example:
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$.Player Views")) AS INT64) AS video_views,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$.Player Starts")) AS INT64) AS player_starts,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - Click Conversion']")) AS INT64) AS click_conversion_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - Click Conversion Revenue']")) AS FLOAT64) AS click_Conversion_revenue_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - Conversion Touch']")) AS INT64) AS conversion_touch_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - Conversion Touch Revenue']")) AS FLOAT64) AS Conversion_Touch_Revenue_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - View Through Conversion']")) AS INT64) AS View_Through_Conversion_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - View Through Conversion Revenue']")) AS FLOAT64) AS View_Through_Conversion_Revenue_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - Time Weighted Decay Conversion']")) AS INT64) AS Time_Weighted_Decay_Conversion_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['01 - Time Weighted Decay Conversion Revenue']")) AS FLOAT64) AS Time_Weighted_Decay_Conversion_Revenue_01,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - Click Conversion']")) AS INT64) AS Click_Conversion_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - Click Conversion Revenue']")) AS FLOAT64) AS Click_Conversion_Revenue_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - Conversion Touch']")) AS INT64) AS Conversion_Touch_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - Conversion Touch Revenue']")) AS FLOAT64) AS Conversion_Touch_Revenue_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - View Through Conversion']")) AS INT64) AS View_Through_Conversion_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - View Through Conversion Revenue']")) AS FLOAT64) AS View_Through_Conversion_Revenue_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - Time Weighted Decay Conversion']")) AS INT64) AS Time_Weighted_Decay_Conversion_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['02 - Time Weighted Decay Conversion Revenue']")) AS FLOAT64) AS Time_Weighted_Decay_Conversion_Revenue_02,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - Click Conversion']")) AS INT64) AS Click_Conversion_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - Click Conversion Revenue']")) AS FLOAT64) AS Click_Conversion_Revenue_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - Conversion Touch']")) AS INT64) AS Conversion_Touch_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - Conversion Touch Revenue']")) AS FLOAT64) AS Conversion_Touch_Revenue_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - View Through Conversion']")) AS INT64) AS View_Through_Conversion_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - View Through Conversion Revenue']")) AS FLOAT64) AS View_Through_Conversion_Revenue_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - Time Weighted Decay Conversion']")) AS INT64) AS Time_Weighted_Decay_Conversion_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['03 - Time Weighted Decay Conversion Revenue']")) AS FLOAT64) AS Time_Weighted_Decay_Conversion_Revenue_03,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - Click Conversion']")) AS INT64) AS Click_Conversion_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - Click Conversion Revenue']")) AS FLOAT64) AS Click_Conversion_Revenue_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - Conversion Touch']")) AS INT64) AS Conversion_Touch_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - Conversion Touch Revenue']")) AS FLOAT64) AS Conversion_Touch_Revenue_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - View Through Conversion']")) AS INT64) AS View_Through_Conversion_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - View Through Conversion Revenue']")) AS FLOAT64) AS View_Through_Conversion_Revenue_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - Time Weighted Decay Conversion']")) AS INT64) AS Time_Weighted_Decay_Conversion_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['04 - Time Weighted Decay Conversion Revenue']")) AS FLOAT64) AS Time_Weighted_Decay_Conversion_Revenue_04,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - Click Conversion']")) AS INT64) AS Click_Conversion_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - Click Conversion Revenue']")) AS FLOAT64) AS Click_Conversion_Revenue_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - Conversion Touch']")) AS INT64) AS Conversion_Touch_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - Conversion Touch Revenue']")) AS FLOAT64) AS Conversion_Touch_Revenue_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - View Through Conversion']")) AS INT64) AS View_Through_Conversion_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - View Through Conversion Revenue']")) AS FLOAT64) AS View_Through_Conversion_Revenue_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - Time Weighted Decay Conversion']")) AS INT64) AS Time_Weighted_Decay_Conversion_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['05 - Time Weighted Decay Conversion Revenue']")) AS FLOAT64) AS Time_Weighted_Decay_Conversion_Revenue_05,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - Click Conversion']")) AS INT64) AS Click_Conversion_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - Click Conversion Revenue']")) AS FLOAT64) AS Click_Conversion_Revenue_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - Conversion Touch']")) AS INT64) AS Conversion_Touch_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - Conversion Touch Revenue']")) AS FLOAT64) AS Conversion_Touch_Revenue_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - View Through Conversion']")) AS INT64) AS View_Through_Conversion_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - View Through Conversion Revenue']")) AS FLOAT64) AS View_Through_Conversion_Revenue_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - Time Weighted Decay Conversion']")) AS INT64) AS Time_Weighted_Decay_Conversion_06,
        CAST(JSON_VALUE(JSON_EXTRACT(data, "$['06 - Time Weighted Decay Conversion Revenue']")) AS FLOAT64) AS Time_Weighted_Decay_Conversion_Revenue_06

    FROM
        `real-nz-main.ttd_raw__tourism.standard_streams`
),
ranked_data AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                Date, partner_id, advertiser_id, campaign_id, ad_group_id, ad_format, creative_id, 
                advertiser, campaign_name, ad_group, creative, deal_id, ad_server_creative_placement_id
        ) AS row_num
    FROM
        parsed_data
),final AS (
select * ,
CASE 
    WHEN LOWER(campaign_name) LIKE '%acast%' OR LOWER(creative) LIKE '%acast%' THEN 'Acast'
    WHEN LOWER(campaign_name) LIKE '%3now%' OR LOWER(creative) LIKE '%3now%' OR LOWER(campaign_name) LIKE '%three%' OR LOWER(creative) LIKE '%three%' THEN 'Threenow'
    WHEN LOWER(campaign_name) LIKE '%nzme%' OR LOWER(creative) LIKE '%nzme%' THEN 'Nzme'
    WHEN LOWER(campaign_name) LIKE '%tvnz%' OR LOWER(creative) LIKE '%tvnz%' THEN 'Tvnz'
    WHEN LOWER(campaign_name) LIKE '%youtube%' OR LOWER(creative) LIKE '%yt%' or lower(creative) LIKE '%youtube%' or   LOWER(campaign_name) LIKE '%yt%' THEN 'Youtube'
    WHEN LOWER(campaign_name) LIKE '%stuff%' OR LOWER(creative) LIKE '%stuff%' THEN 'Stuff'
    ELSE 'Ttd'
END AS publisher,
CASE 
    WHEN ARRAY_LENGTH(SPLIT(ad_group,'_')) > 3 and SPLIT(ad_group,'_')[OFFSET(2)] LIKE '%DISP%' THEN 'Display'
    WHEN lower(ad_group) LIKE '%vidod%' or lower(campaign_name) like '%vidod%'
    or lower(creative) like '%vidod%' then 'Video OnDemand'
else 'Other'
END AS media_format,
CASE
    WHEN ARRAY_LENGTH(SPLIT(creative,'_')) <8 THEN 'Other'
    ELSE
        SPLIT(creative,'_')[OFFSET(7)] 
END AS audience_name,
CASE 
    WHEN ARRAY_LENGTH(SPLIT(creative,'_')) <8 THEN 'Other'
    ELSE
        SPLIT(creative,'_')[OFFSET(5)] 
END AS creative_descr,
CASE 
    WHEN ARRAY_LENGTH(SPLIT(creative,'_')) <8 THEN 'Other'
    ELSE
        SPLIT(creative,'_')[OFFSET(7)] 
END AS ad_format_detail,
CASE
    WHEN ARRAY_LENGTH(SPLIT(campaign_name,'_')) <=1 THEN 'Other'
    ELSE
        SPLIT(campaign_name,'_')[OFFSET(1)] 
END AS campaign_descr

from ranked_data where row_num = 1
)
  SELECT 
        ad_server_creative_placement_id,
        date, -- Keep this as-is for joining purposes
        campaign_name,
        campaign_id,
        creative as creative_name,
        creative_id,
        advertiser,
        advertiser_id,
        publisher,
        media_format,
        audience_name,
        ad_format,
        ad_format_detail,
        creative_descr,
        campaign_descr,
        SUM(player_25_complete) AS video_25_completion,
        SUM(player_50_complete) AS video_50_completion,
        SUM(player_75_complete) AS video_75_completion,
        SUM(player_100_complete) AS video_completion,
        SUM(clicks) AS clicks,
        SUM(video_views) AS video_views,
        SUM(impressions) AS impressions,
        SUM(partner_cost_partner_currency) AS media_cost -- Aggregate Partner Cost
    FROM final
    GROUP BY 
        ad_server_creative_placement_id, date, campaign_name, campaign_id, creative, creative_id, advertiser, advertiser_id,publisher,media_format,
        audience_name,ad_format,ad_format_detail,creative_descr,campaign_descr
