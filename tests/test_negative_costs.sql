-- ============================================================================
-- Teste Customizado: Validação de Custos Negativos
-- ============================================================================
-- Garante que não há custos negativos em nenhuma das camadas (staging e marts)
-- Possível indicador de erro de ETL ou dados corrompidos

with staging_costs as (
  select 'stg_google_ads' as tbl, ad_cost
  from {{ ref('stg_google_ads') }}
  union all
  select 'stg_facebook_ads' as tbl, ad_cost
  from {{ ref('stg_facebook_ads') }}
  union all
  select 'stg_tiktok_ads' as tbl, ad_cost
  from {{ ref('stg_tiktok_ads') }}
),

invalid_costs as (
  select tbl, count(*) as count_negative
  from staging_costs
  where ad_cost < 0
  group by 1
)

select * from invalid_costs where count_negative > 0
