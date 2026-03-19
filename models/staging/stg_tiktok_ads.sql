-- ============================================================================
-- Modelo: stg_tiktok_ads.sql
-- Camada: Staging
-- Tipo: View
-- Descrição:
--   Extrai e normaliza dados brutos do TikTok Ads do JSON (raw_payload).
--   Padroniza nomes de colunas para o modelo canonical de marketing.
--
-- Lógica:
--   1. Importa dados da source raw_tiktok_ads
--   2. Descompacta JSON usando sintaxe Snowflake (col:chave::tipo)
--   3. Renomeia colunas para padrão canonical
--   4. Adiciona coluna de plataforma (constante)
--
-- Estrutura do JSON de entrada:
--   {
--     "camp_id": "T1",
--     "camp_name": "Summer Promo",
--     "spend": 50.00,
--     "stat_time": "2023-10-01"
--   }
--
-- Saída esperada de colunas:
--   raw_id, synced_timestamp, campaign_id, campaign_name, ad_cost, 
--   ad_date, platform
-- ============================================================================

with source as (
    -- Importa todos os registros da tabela bruta de TikTok Ads
    select
        *
    from {{ source('fivetran_raw', 'raw_tiktok_ads') }}
),

parsed_json as (
    -- Extrai e converte os campos JSON para tipos apropriados
    -- Snowflake usa a sintaxe: column:key::type para extração tipada
    -- Note: TikTok usa "camp_id", "camp_name", "spend", e "stat_time" como nomes de campos
    select
        id as raw_id,
        synced_timestamp,
        raw_payload:camp_id::string as campaign_id,
        raw_payload:camp_name::string as campaign_name,
        raw_payload:spend::numeric(10, 2) as ad_cost,
        raw_payload:stat_time::date as ad_date,
        'TikTok Ads' as platform
    from source
),

final as (
    -- Seleção e ordem das colunas para saída
    select
        raw_id,
        synced_timestamp,
        campaign_id,
        campaign_name,
        ad_cost,
        ad_date,
        platform
    from parsed_json
)

select * from final
