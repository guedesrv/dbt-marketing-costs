-- ============================================================================
-- Teste Customizado: Validação de Plataformas Esperadas
-- ============================================================================
-- Garante que sempre temos exatamente 3 plataformas cadastradas
-- (Google Ads, Facebook Ads, TikTok Ads)

with expected_platforms as (
  select
    'Google Ads' as platform_name
  union all
  select 'Facebook Ads'
  union all
  select 'TikTok Ads'
),

actual_platforms as (
  select distinct platform_name
  from {{ ref('dim_platforms') }}
),

missing_platforms as (
  select ep.platform_name
  from expected_platforms ep
  where ep.platform_name not in (select platform_name from actual_platforms)
),

extra_platforms as (
  select ap.platform_name
  from actual_platforms ap
  where ap.platform_name not in (select platform_name from expected_platforms)
)

select 
  'missing' as validation_type,
  platform_name
from missing_platforms

union all

select 
  'extra' as validation_type,
  platform_name
from extra_platforms
