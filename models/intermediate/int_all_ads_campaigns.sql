-- ============================================================================
-- Modelo: int_all_ads_campaigns.sql
-- Camada: Intermediate
-- Tipo: Ephemeral (não materializado, inlined em outras queries)
-- Descrição:
--   Consolida os dados normalizados de todas as 3 plataformas de ads
--   em uma única tabela padronizada através de UNION ALL.
--
-- Lógica:
--   1. Importa stg_google_ads
--   2. Importa stg_facebook_ads
--   3. Importa stg_tiktok_ads
--   4. Realiza UNION ALL de todas as tabelas
--   5. Cria campaign_sk (surrogate key) usando hash MD5
--
-- Por que surrogate key?
--   Os IDs de campanha variam por plataforma (números ou strings).
--   Para criar relacionamentos semânticos na tabela fato, geramos um hash único
--   combinando o campaign_id + platform_name. Isso garante que:
--   - Nenhuma colisão entre plataformas
--   - Estabilidade (mesmo ID sempre gera mesmo hash)
--   - Performance de join
--
-- Saída de colunas:
--   campaign_sk, raw_id, synced_timestamp, campaign_id, campaign_name, 
--   ad_cost, ad_date, platform
-- ============================================================================

with google_ads as (
    select
        raw_id,
        synced_timestamp,
        campaign_id,
        campaign_name,
        ad_cost,
        ad_date,
        platform
    from {{ ref('stg_google_ads') }}
),

facebook_ads as (
    select
        raw_id,
        synced_timestamp,
        campaign_id,
        campaign_name,
        ad_cost,
        ad_date,
        platform
    from {{ ref('stg_facebook_ads') }}
),

tiktok_ads as (
    select
        raw_id,
        synced_timestamp,
        campaign_id,
        campaign_name,
        ad_cost,
        ad_date,
        platform
    from {{ ref('stg_tiktok_ads') }}
),

unioned as (
    -- Consolida todos os dados de ads em uma única view
    select * from google_ads
    union all
    select * from facebook_ads
    union all
    select * from tiktok_ads
),

with_campaign_surrogate_key as (
    -- Gera uma chave substituta (surrogate key) para cada combinação 
    -- única de campaign_id + platform. Isso garante identidade única
    -- entre plataformas.
    select
        {{ dbt_utils.generate_surrogate_key(['campaign_id', 'platform']) }} as campaign_sk,
        raw_id,
        synced_timestamp,
        campaign_id,
        campaign_name,
        ad_cost,
        ad_date,
        platform
    from unioned
)

select * from with_campaign_surrogate_key
