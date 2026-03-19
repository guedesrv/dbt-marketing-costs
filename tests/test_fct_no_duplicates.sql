-- ============================================================================
-- Teste Customizado: Duplicatas em Tabela Fato
-- ============================================================================
-- Garante que não há duplicatas na tabela fato (combinação única de 
-- campaign_sk + date_sk + platform_sk)

select 
  campaign_sk,
  date_sk,
  platform_sk,
  count(*) as num_records
from {{ ref('fct_campaign_performance') }}
group by 1, 2, 3
having count(*) > 1
