{{ config(
    materialized='table',
) }}
with basic as (
SELECT 
  JSON_VALUE(data, '$.datetime') AS date,
  JSON_VALUE(data, '$.campaign') AS campaign_name,
  CAST(JSON_VALUE(data, '$.campaign_id') AS INT64) AS campaign_id,
  JSON_VALUE(data, '$.city') AS city,
  JSON_VALUE(data, '$.creative') AS creative_name,
  JSON_VALUE(data, '$.line_item') AS line_item,
  CAST(JSON_VALUE(data, '$.line_item_id') AS INT64) AS line_item_id,
  CAST(REPLACE(JSON_VALUE(data, '$.concentration'), '%', '') AS FLOAT64) AS concentration,
  CAST(JSON_VALUE(data, '$.impressions') AS FLOAT64) AS impressions,
  CAST(JSON_VALUE(data, '$.plays') AS INT64) AS plays,
  CAST(JSON_VALUE(data, '$.progress') AS FLOAT64) AS progress,
  CAST(JSON_VALUE(data, '$.spend') AS FLOAT64) AS media_cost,
  ROW_NUMBER() OVER (
      PARTITION BY CAST(JSON_VALUE(data, '$.campaign_id') AS INT64), CAST(JSON_VALUE(data, '$.line_item_id') AS INT64),JSON_VALUE(data, '$.datetime'),
      JSON_VALUE(data, '$.creative'),CAST(JSON_VALUE(data, '$.plays') AS INT64)
  ) as row_num ,
  FROM `real-nz-main.hivestack_raw__tourism.realnz_tourism_report`),
  deduplicate_data AS (
    SELECT date,campaign_name,campaign_id,city,creative_name,line_item,line_item_id,concentration,impressions,plays,progress,media_cost,
    row_num FROM basic where row_num = 1
  ) , populate_data as (
  SELECT SUM(impressions) AS impressions,
  SUM(media_cost) AS media_cost,
  SUM(plays) AS plays,
  campaign_name,
  campaign_id,
  city,
  creative_name,
  line_item,
  CASE 
    WHEN ARRAY_LENGTH(SPLIT(line_item,'_'))>=8 THEN SPLIT(line_item,'_')[7]
    ELSE 'Other'
  END AS audience_name,
  CASE
    WHEN ARRAY_LENGTH(SPLIT(campaign_name,'_'))>=1 THEN SPLIT(campaign_name,'_')[1]
    ELSE 'Other'
  END AS campaign_descr,
  CASE 
    WHEN ARRAY_LENGTH(SPLIT(creative_name,'_')) <8 THEN 'Other'
    ELSE
        SPLIT(creative_name,'_')[OFFSET(7)] 
  END AS ad_format_detail,
  CASE 
    WHEN ARRAY_LENGTH(SPLIT(creative_name,'_')) <8 THEN 'Other'
    ELSE
        SPLIT(creative_name,'_')[OFFSET(5)] 
  END AS creative_descr,
  CASE 
    WHEN ARRAY_LENGTH(SPLIT(creative_name,'_')) <8 THEN 'Other'
    ELSE
        SPLIT(creative_name,'_')[OFFSET(6)] 
  END AS ad_format,
  'Hivestack' AS publisher,
  'PDOOH' AS media_format,
  line_item_id,
  concentration,
  date,
  progress
  FROM deduplicate_data
  GROUP BY campaign_name,campaign_id,city,creative_name,line_item,line_item_id,concentration,date,progress

 
  )
SELECT SUM(impressions) as impressions,SUM(media_cost) as media_cost,creative_name, ad_format,campaign_name, media_format,0 as clicks ,audience_name,ad_format_detail,DATE(date) as date ,publisher, campaign_descr,creative_descr FROM populate_data group by campaign_name,media_format,ad_format_detail,campaign_descr,creative_name,audience_name,publisher,creative_descr,date,ad_format