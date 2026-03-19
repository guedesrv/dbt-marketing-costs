-- ============================================================================
-- Teste Customizado: Integridade de Chaves Estrangeiras
-- ============================================================================
-- Garante que todas as chaves estrangeiras na tabela fato apontam para 
-- registros válidos nas dimensões.

select *
from {{ ref('fct_campaign_performance') }} fct
where 
  campaign_sk not in (select campaign_sk from {{ ref('dim_campaigns') }})
  or date_sk not in (select date_sk from {{ ref('dim_dates') }})
  or platform_sk not in (select platform_sk from {{ ref('dim_platforms') }})
having count(*) > 0
