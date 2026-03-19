-- ============================================================================
-- Modelo: stg_facebook_ads.sql
-- Camada: Staging
-- Tipo: View
-- Descrição:
--   Extrai e normaliza dados brutos do Facebook Ads do JSON (raw_payload).
--   Padroniza nomes de colunas para o modelo canonical de marketing.
--
-- Lógica:
--   1. Importa dados da source raw_facebook_ads
--   2. Descompacta JSON usando sintaxe Snowflake (col:chave::tipo)
--   3. Renomeia colunas para padrão canonical
--   4. Adiciona coluna de plataforma (constante)
--
-- Estrutura do JSON de entrada:
--   {
--     "campaign_id": "A1",
--     "campaign_name": "Brand Awareness",
--     "amount_spent": 200.00,
--     "spending_date": "2023-10-01"
--   }
--
-- Saída esperada de colunas:
--   raw_id, synced_timestamp, campaign_id, campaign_name, ad_cost, 
--   ad_date, platform
-- ============================================================================

with source as (
    -- Importa todos os registros da tabela bruta de Facebook Ads
    select
        *
    from {{ source('fivetran_raw', 'raw_facebook_ads') }}
),

parsed_json as (
    -- Extrai e converte os campos JSON para tipos apropriados
    -- Snowflake usa a sintaxe: column:key::type para extração tipada
    -- Note: Facebook usa "amount_spent" e "spending_date" como nomes de campos
    select
        id as raw_id,
        synced_timestamp,
        raw_payload:campaign_id::string as campaign_id,
        raw_payload:campaign_name::string as campaign_name,
        raw_payload:amount_spent::numeric(10, 2) as ad_cost,
        raw_payload:spending_date::date as ad_date,
        'Facebook Ads' as platform
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
