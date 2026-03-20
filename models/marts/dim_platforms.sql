-- ============================================================================
-- Modelo: dim_platforms.sql
-- Camada: Marts
-- Tipo: Table
-- Descrição:
--   Dimensão conforma as plataformas de publicidade suportadas.
--   Cada linha representa uma plataforma única com seus metadados.
--
-- Regras de Negócio:
--   - Tabela pequena e estática (apenas 3 plataformas)
--   - Cada plataforma tem um platform_sk (Surrogate Key)
--   - Dados definidos como VALUES inline (sem dependência externa)
--
-- Saída de colunas:
--   platform_sk, platform_name, platform_description
-- ============================================================================

with platforms as (
    -- Define as plataformas conhecidas do projeto
    select
        {{ dbt_utils.generate_surrogate_key(['platform_name']) }} as platform_sk,
        platform_name,
        platform_description
    from (
        values
            ('Google Ads', 'Google Ads - Rede de Busca e Display'),
            ('Facebook Ads', 'Meta Platforms - Facebook e Instagram Ads'),
            ('TikTok Ads', 'ByteDance - TikTok Ads Platform')
    ) as t(platform_name, platform_description)
),

final as (
    select
        platform_sk,
        platform_name,
        platform_description,
        current_timestamp() as dbt_created_at,
        current_timestamp() as dbt_updated_at
    from platforms
)

select * from final
