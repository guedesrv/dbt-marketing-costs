-- ============================================================================
-- Modelo: dim_campaigns.sql
-- Camada: Marts
-- Tipo: Table
-- Descrição: Dimensão de campanhas únicas
-- ============================================================================

select
    campaign_sk,
    campaign_id,
    campaign_name,
    platform,
    current_timestamp() as dbt_created_at,
    current_timestamp() as dbt_updated_at
from {{ ref('int_all_ads_campaigns') }}
qualify row_number() over (partition by campaign_sk order by 1) = 1
