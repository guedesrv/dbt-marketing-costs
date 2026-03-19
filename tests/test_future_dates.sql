-- ============================================================================
-- Teste Customizado: Datas Futuras (Validação de Integridade)
-- ============================================================================
-- Garante que não há datas futuras nos dados de ads (devem ser históricos)

with future_dates as (
  select 'stg_google_ads' as tbl, ad_date
  from {{ ref('stg_google_ads') }}
  union all
  select 'stg_facebook_ads' as tbl, ad_date
  from {{ ref('stg_facebook_ads') }}
  union all
  select 'stg_tiktok_ads' as tbl, ad_date
  from {{ ref('stg_tiktok_ads') }}
),

invalid_dates as (
  select 
    tbl,
    max(ad_date) as max_future_date,
    count(*) as count_future_records
  from future_dates
  where ad_date > current_date()
  group by 1
)

select * from invalid_dates where count_future_records > 0
