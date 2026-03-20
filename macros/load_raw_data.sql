-- Macro para carregar dados brutos de marketing (simula Fivetran)
-- Executar com: dbt run-operation load_raw_data

{% macro load_raw_data() %}
  {% if execute %}
    -- Google Ads
    {% do run_query("
      CREATE OR REPLACE TABLE " ~ target.database ~ ".raw_marketing.raw_google_ads AS
      SELECT 
        1 as ID, 
        '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, 
        PARSE_JSON('{\"campaign_id\": 101, \"campaign_name\": \"Summer Campaign 2023\", \"cost\": 150.50, \"date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 2 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 101, \"campaign_name\": \"Summer Campaign 2023\", \"cost\": 155.75, \"date\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 3 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 102, \"campaign_name\": \"Brand Awareness Q4\", \"cost\": 200.25, \"date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 4 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 102, \"campaign_name\": \"Brand Awareness Q4\", \"cost\": 198.50, \"date\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 5 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 103, \"campaign_name\": \"Holiday Promo\", \"cost\": 300.00, \"date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 6 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 103, \"campaign_name\": \"Holiday Promo\", \"cost\": 310.25, \"date\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 7 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 104, \"campaign_name\": \"Back to School\", \"cost\": 125.50, \"date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 8 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": 104, \"campaign_name\": \"Back to School\", \"cost\": 130.75, \"date\": \"2023-10-02\"}') as RAW_PAYLOAD
    ") %}

    -- Facebook Ads
    {% do run_query("
      CREATE OR REPLACE TABLE " ~ target.database ~ ".raw_marketing.raw_facebook_ads AS
      SELECT 
        1 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A1\", \"campaign_name\": \"Brand Awareness\", \"amount_spent\": 200.00, \"spending_date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 2 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A1\", \"campaign_name\": \"Brand Awareness\", \"amount_spent\": 210.50, \"spending_date\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 3 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A2\", \"campaign_name\": \"Conversion Campaign\", \"amount_spent\": 250.75, \"spending_date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 4 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A2\", \"campaign_name\": \"Conversion Campaign\", \"amount_spent\": 255.25, \"spending_date\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 5 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A3\", \"campaign_name\": \"Engagement Drive\", \"amount_spent\": 175.50, \"spending_date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 6 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A3\", \"campaign_name\": \"Engagement Drive\", \"amount_spent\": 180.00, \"spending_date\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 7 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A4\", \"campaign_name\": \"Remarketing\", \"amount_spent\": 300.25, \"spending_date\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 8 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"campaign_id\": \"A4\", \"campaign_name\": \"Remarketing\", \"amount_spent\": 305.50, \"spending_date\": \"2023-10-02\"}') as RAW_PAYLOAD
    ") %}

    -- TikTok Ads
    {% do run_query("
      CREATE OR REPLACE TABLE " ~ target.database ~ ".raw_marketing.raw_tiktok_ads AS
      SELECT 
        1 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T1\", \"camp_name\": \"Summer Promo\", \"spend\": 50.00, \"stat_time\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 2 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T1\", \"camp_name\": \"Summer Promo\", \"spend\": 52.50, \"stat_time\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 3 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T2\", \"camp_name\": \"Viral Challenge\", \"spend\": 75.25, \"stat_time\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 4 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T2\", \"camp_name\": \"Viral Challenge\", \"spend\": 78.75, \"stat_time\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 5 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T3\", \"camp_name\": \"Influencer Collab\", \"spend\": 100.50, \"stat_time\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 6 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T3\", \"camp_name\": \"Influencer Collab\", \"spend\": 105.00, \"stat_time\": \"2023-10-02\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 7 as ID, '2023-10-01 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T4\", \"camp_name\": \"Product Launch\", \"spend\": 150.25, \"stat_time\": \"2023-10-01\"}') as RAW_PAYLOAD
      UNION ALL
      SELECT 8 as ID, '2023-10-02 10:00:00'::timestamp_ntz as SYNCED_TIMESTAMP, PARSE_JSON('{\"camp_id\": \"T4\", \"camp_name\": \"Product Launch\", \"spend\": 155.50, \"stat_time\": \"2023-10-02\"}') as RAW_PAYLOAD
    ") %}

    {% do log("✅ Raw data loaded successfully", info=true) %}
  {% endif %}

{% endmacro %}

