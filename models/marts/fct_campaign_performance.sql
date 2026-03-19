-- ============================================================================
-- Modelo: fct_campaign_performance.sql
-- Camada: Marts
-- Tipo: Table
-- Descrição:
--   Tabela fato do modelo estrela que consolida as métricas de performance
--   de campanhas de publicidade por dia.
--
-- Arquitetura:
--   - Granularidade: 1 linha = 1 campanha + 1 dia específico
--   - Relacionamento: campaign_sk (FK -> dim_campaigns)
--   - Relacionamento: platform_sk (FK -> dim_platforms)
--   - Relacionamento: date_sk (FK -> dim_dates)
--   - Fatos: ad_cost (métrica aditiva)
--
-- Lógica:
--   1. Importa dados do intermediate (todas as ads consolidadas)
--   2. Faz join com dim_dates para obter date_sk
--   3. Faz join com dim_platforms para obter platform_sk
--   4. Agrupa por campaign_sk, date_sk para consolidar multiplos registros
--      (caso o Fivetran tenha ingerido múltiplas linhas no mesmo dia)
--
-- Saída de colunas:
--   campaign_sk, date_sk, platform_sk, total_ad_cost
-- ============================================================================

with ads_data as (
    -- Importa os dados consolidados de todas as plataformas
    select
        campaign_sk,
        campaign_id,
        campaign_name,
        ad_cost,
        ad_date,
        platform,
        raw_id
    from {{ ref('int_all_ads_campaigns') }}
),

dates as (
    -- Importa a dimensão de datas para obter date_sk
    select
        date_sk,
        full_date
    from {{ ref('dim_dates') }}
),

platforms as (
    -- Importa a dimensão de plataformas para obter platform_sk
    select
        platform_sk,
        platform_name
    from {{ ref('dim_platforms') }}
),

joined_with_dimensions as (
    -- Junta os dados de ads com as dimensões usando o padrão Kimball
    select
        ads.campaign_sk,
        dates.date_sk,
        platforms.platform_sk,
        ads.ad_cost,
        ads.raw_id
    from ads_data ads
    left join dates on ads.ad_date = dates.full_date
    left join platforms on ads.platform = platforms.platform_name
),

aggregated_metrics as (
    -- Agrupa por chaves estrangeiras para consolidar métricas do dia
    -- (caso haja múltiplos registros para a mesma campanha+data)
    select
        campaign_sk,
        date_sk,
        platform_sk,
        sum(ad_cost) as total_ad_cost,
        count(raw_id) as number_of_records
    from joined_with_dimensions
    where date_sk is not null  -- Filtra datas fora do intervalo da dimensão
    group by 1, 2, 3
),

final as (
    select
        campaign_sk,
        date_sk,
        platform_sk,
        total_ad_cost,
        number_of_records,
        current_timestamp() as dbt_created_at,
        current_timestamp() as dbt_updated_at
    from aggregated_metrics
)

select * from final

