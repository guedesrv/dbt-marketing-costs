-- ============================================================================
-- Modelo: stg_google_ads.sql
-- Camada: Staging
-- Tipo: View
-- Descrição:
--   Extrai e normaliza dados brutos do Google Ads do JSON (raw_payload).
--   Padroniza nomes de colunas para o modelo canonical de marketing.
--
-- Lógica:
--   1. Importa dados da source raw_google_ads
--   2. Descompacta JSON usando sintaxe Snowflake (col:chave::tipo)
--   3. Renomeia colunas para padrão canonical
--   4. Adiciona coluna de plataforma (constante)
--
-- Estrutura do JSON de entrada:
--   {
--     "campaign_id": 1,
--     "campaign_name": "Summer Campaign 2023",
--     "cost": 150.50,
--     "date": "2023-10-01"
--   }
--
-- Saída esperada de colunas:
--   raw_id, synced_timestamp, campaign_id, campaign_name, ad_cost, 
--   ad_date, platform
-- ============================================================================

with source as (
    -- Importa todos os registros da tabela bruta de Google Ads do Fivetran
    select
        id as raw_id,
        synced_timestamp,
        raw_payload
    from {{ source('fivetran_raw', 'raw_google_ads') }}
),

parsed as (
    -- Descompacta o JSON usando sintaxe nativa do Snowflake
    select
        raw_id,
        synced_timestamp,
        raw_payload:campaign_id::integer as campaign_id,
        raw_payload:campaign_name::varchar as campaign_name,
        raw_payload:cost::numeric(10, 2) as ad_cost,
        raw_payload:date::date as ad_date,
        'Google Ads' as platform
    from source
)

select * from parsed

