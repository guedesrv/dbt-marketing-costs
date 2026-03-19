-- ============================================================================
-- Modelo: dim_campaigns.sql
-- Camada: Marts
-- Tipo: Table
-- Descrição:
--   Dimensão conforma as campanhas únicas de todas as plataformas.
--   Cada linha representa uma campanha única (combinação de campaign_id + 
--   platform), com seu rótulo e metadados descritivos.
--
-- Regras de Negócio:
--   - Uma campanha = combinação única de (campaign_id, platform)
--   - Cada campanha tem exatamente um campaign_sk (Surrogate Key)
--   - Dimensão lentamente mutável (Type 1): sobrescreve dados ao atualizar
--
-- Saída de colunas:
--   campaign_sk, campaign_id, campaign_name, platform
-- ============================================================================

with campaigns as (
    -- Importa os dados consolidados da camada intermediate
    select
        campaign_sk,
        campaign_id,
        campaign_name,
        platform
    from {{ ref('int_all_ads_campaigns') }}
),

deduplicated as (
    -- Remove duplicatas, mantendo apenas registros únicos
    -- (pode haver múltiplas linhas para a mesma campanha em diferentes datas)
    select distinct
        campaign_sk,
        campaign_id,
        campaign_name,
        platform
    from campaigns
),

final as (
    select
        campaign_sk,
        campaign_id,
        campaign_name,
        platform,
        current_timestamp() as dbt_created_at,
        current_timestamp() as dbt_updated_at
    from deduplicated
)

select * from final
