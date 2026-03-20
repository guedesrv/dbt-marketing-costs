-- ============================================================================
-- Teste Customizado: Integridade de Chaves Estrangeiras
-- ============================================================================
-- Garante que todas as chaves estrangeiras na tabela fato apontam para 
-- registros válidos nas dimensões.
-- 
-- Configurado como aviso (severity: warn) para permitir auditoria sem bloquear
-- o pipeline em caso de registros órfãos.

select count(*) as invalid_foreign_keys
from {{ ref('fct_campaign_performance') }} fct
where 
  campaign_sk not in (select campaign_sk from {{ ref('dim_campaigns') }})
  or date_sk not in (select date_sk from {{ ref('dim_dates') }})
  or platform_sk not in (select platform_sk from {{ ref('dim_platforms') }})
{{ config(severity = 'warn') }}
