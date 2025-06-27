{{ config(
    materialized='table',
) }}
WITH channels as (
  SELECT *,
    -- Define channel using the resolved site_name field in this CTE
    CASE 
        WHEN LOWER(site_name) LIKE '%acast%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%adfenix%' THEN 'Owned Display'
        WHEN LOWER(site_name) LIKE '%adobe%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%apple_ads_search%' THEN 'Paid Search'
        WHEN LOWER(site_name) LIKE '%bing_ads_search%' THEN 'Paid Search'
        WHEN LOWER(site_name) LIKE '%blis%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%business_desk%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%clearscore%' THEN 'Affiliate'
        WHEN LOWER(site_name) LIKE '%dart_search%' THEN 'Paid Search'
        WHEN LOWER(site_name) LIKE '%demand_gen%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%direct%' THEN 'Direct'
        WHEN LOWER(site_name) LIKE '%dv_360%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%dv360%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%email%' THEN 'Email'
        WHEN LOWER(site_name) LIKE '%facebook%' THEN 'Paid Social'
        WHEN LOWER(site_name) LIKE '%gdn%' THEN 'Owned Display'
        WHEN LOWER(site_name) LIKE '%gmb%' THEN 'Google My Business'
        WHEN LOWER(site_name) LIKE '%google_ads_display%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%google_ads_search%' THEN 'Paid Search'
        WHEN LOWER(site_name) LIKE '%google_my_business%' THEN 'Google My Business'
        WHEN LOWER(site_name) LIKE '%homes.co.nz%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%linkedin%' THEN 'Paid Social'
        WHEN LOWER(site_name) LIKE '%listinglogic%' THEN 'Owned Display'
        WHEN LOWER(site_name) LIKE '%mediaworks%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%metservice%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%nzh_business%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%nzherald%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%nzme%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%organic search%' THEN 'Organic Search'
        WHEN LOWER(site_name) LIKE '%organic social%' THEN 'Organic Social'
        WHEN LOWER(site_name) LIKE '%outbrain%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%own_social%' THEN 'Owned Social'
        WHEN LOWER(site_name) LIKE '%pinterest%' THEN 'Paid Social'
        WHEN LOWER(site_name) LIKE '%quora%' THEN 'Paid Social'
        WHEN LOWER(site_name) LIKE '%referral%' THEN 'Referral'
        WHEN LOWER(site_name) LIKE '%rem%' THEN 'Owned Display'
        WHEN LOWER(site_name) LIKE '%snapchat%' THEN 'Paid Social'
        WHEN LOWER(site_name) LIKE '%spotify%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%stuff%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%teads%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%tiktok%' THEN 'Paid Social'
        WHEN LOWER(site_name) LIKE '%trademe%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%ttd%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%tvnz%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%twitch%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%verizon%' THEN 'Paid Display'
        WHEN LOWER(site_name) LIKE '%youtube%' THEN 'Paid Display'
        ELSE 'Unknown'
    END AS channel
  FROM {{ ref('ga4_goal_a__tourism') }}
),
with_channel AS (
select *,
  CASE 
                WHEN LOWER(sessionSourceMedium) LIKE '%facebook%' THEN 'Facebook'
                WHEN LOWER(site_name) LIKE '%demand_gen%' THEN 'Demand Gen'
                WHEN LOWER(site_name) LIKE '%google_ads_search%' THEN 'Google Ads Search'
                WHEN LOWER(sessionSourceMedium) LIKE '%ttd%' THEN 'Ttd'
                WHEN LOWER(sessionSourceMedium) LIKE '%tiktok%' THEN 'Tiktok'
                WHEN LOWER(sessionSourceMedium) LIKE '%snapchat%' THEN 'Snapchat'
                WHEN LOWER(sessionSourceMedium) LIKE '%youtube%' OR LOWER(sessionSourceMedium) LIKE '%yt%' THEN 'Youtube'
                WHEN LOWER(sessionSourceMedium) LIKE '%3now%' OR LOWER(sessionSourceMedium) LIKE '%three%' THEN 'Threenow'
                WHEN LOWER(sessionSourceMedium) LIKE '%nzme%' THEN 'Nzme'
                WHEN LOWER(sessionSourceMedium) LIKE '%acast%' THEN 'Acast'
                WHEN (LOWER(site_name) like '%ttd%' or lower(site_name) like '%dv360%' ) and (lower(sessionCampaignName) like '%youtube%'
                or lower(sessionCampaignName) like '%yt%' or lower(sessionManualAdContent) like '%yt%' or lower(sessionManualAdContent) like '%youtube%') THEN 'Youtube'
                WHEN (LOWER(site_name) like '%ttd%' or lower(site_name) like '%dv360%' ) and (lower(sessionCampaignName) like '%nzme%' 
                or lower(sessionManualAdContent) like '%nzme%') THEN 'Nzme'
                WHEN (LOWER(site_name) like '%ttd%' or lower(site_name) like '%dv360%' ) and (lower(sessionCampaignName) like '%tvnz%' or lower(sessionManualAdContent)
                like '%tvnz%') THEN 'Tvnz'
                WHEN (LOWER(site_name) like '%ttd%' or lower(site_name) like '%dv360%' ) and (lower(sessionCampaignName) like '%3now%' or lower(sessionManualAdContent)
                like '%three%' or lower(sessionManualAdContent) like '%3now%' or lower(sessionCampaignName) like '%three%') THEN 'Threenow'
                WHEN (LOWER(site_name) like '%ttd%' or lower(site_name) like '%dv360%') and (lower(sessionCampaignName) like '%stuff%' or lower(sessionManualAdContent) like '%stuff%' )
                THEN 'Stuff'
                WHEN (LOWER(site_name) LIKE '%dv360%' or lower(site_name)like '%metservice%') and (lower(sessionCampaignName) like '%metservice%' or lower(sessionManualAdContent) like '%metservice%') THEN 'Metservice'
                WHEN (LOWER(site_name) LIKE '%dv360%' or lower(site_name)like '%mediaworks%') and (lower(sessionCampaignName) like '%mediaworks%' or lower(sessionManualAdContent) like '%mediaworks%') THEN 'Mediaworks'
                WHEN (LOWER(site_name) LIKE '%dv360%' or lower(site_name) like '%nzme%') and (lower(sessionCampaignName) like '%buseinss%' and lower(sessionCampaignName) like 'desk%') THEN 'Business Desk'
                WHEN (LOWER(site_name) LIKE '%dv360%' or lower(site_name) like '%nzme%') and (lower(sessionManualAdContent) like '%buseinss%' and lower(sessionManualAdContent) like 'desk%') THEN 'Business Desk'
                WHEN (LOWER(site_name) like '%business%' and lower(site_name) like '%desk%') THEN 'Business Desk'
                WHEN (LOWER(site_name) like '%ttd%' or lower(site_name) like '%dv360%' ) AND (LOWER(sessionCampaignName) like '%acast%' or lower(sessionManualAdContent) like '%acast%') THEN 'Acast'
                WHEN (LOWER(sessionCampaignName) LIKE '%perf%' and lower(sessionCampaignName) like '%max%') or lower(sessionCampaignName) like '%pmax%' THEN '%Performance Max'
                ELSE INITCAP(sessionSourceMedium)
            END AS publisher,

from channels),
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
CASE WHEN 
       lower(camb.campaign_name_raw) = lower(deduplicate_raw.campaign_name_raw) 
       
       THEN deduplicate_raw.campaign_name_raw
       ELSE camb.campaign_name_raw
END AS campaign_name_selection
 FROM campaign_base camb LEFT JOIN deduplicate_raw ON LOWER(deduplicate_raw.campaign_name_raw) = LOWER(camb.campaign_name_raw)