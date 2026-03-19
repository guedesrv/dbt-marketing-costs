# ============================================================================
# DOCUMENTAÇÃO DE TESTES - dbt Marketing Analytics
# ============================================================================
# Este arquivo documenta todos os testes implementados no projeto,
# incluindo testes genéricos (dbt generics) e testes SQL customizados.

## 📊 RESUMO DE TESTES POR CAMADA

### STAGING (models/staging/staging.yml)
- **stg_google_ads**: 20 testes
- **stg_facebook_ads**: 20 testes
- **stg_tiktok_ads**: 20 testes

**Total Staging**: 60 testes

**Tipos de Testes**:
1. `not_null` - Garante que colunas críticas estão preenchidas
2. `unique` - raw_id deve ser único em cada plataforma
3. `accepted_values` - Platform sempre é a constante esperada
4. `expression_is_true` - Validações customizadas:
   - ad_cost >= 0 (sem custos negativos)
   - ad_date <= current_date() (sem datas futuras)
   - length(campaign_id) > 0 (IDs não vazios)
   - length(trim(campaign_name)) > 0 (nomes não em branco)

---

## 🏪 MARTS (models/marts/schema.yml)

### dim_campaigns
- ✅ campaign_sk: unique + not_null
- ✅ campaign_id: not_null
- ✅ campaign_name: not_null
- ✅ platform: not_null + accepted_values (Google, Facebook, TikTok)

**Total**: 7 testes

---

### dim_platforms
- ✅ platform_sk: unique + not_null
- ✅ platform_name: unique + not_null + accepted_values
- ✅ platform_description: not_null

**Total**: 6 testes

---

### dim_dates
- ✅ date_sk: unique + not_null
- ✅ full_date: unique + not_null
- ✅ year: not_null
- ✅ month: not_null + range validation (1-12)
- ✅ week: not_null + range validation (1-53)
- ✅ day_of_week: not_null + range validation (1-7)
- ✅ day_name: not_null
- ✅ is_weekend: not_null
- ✅ is_holiday: not_null

**Total**: 14 testes

---

### fct_campaign_performance (PRINCIPAL)
- ✅ campaign_sk: not_null + relationships(dim_campaigns)
- ✅ date_sk: not_null + relationships(dim_dates)
- ✅ platform_sk: not_null + relationships(dim_platforms)
- ✅ total_ad_cost: not_null + >= 0 + <= 9999999.99 + not_null_proportion (99%)
- ✅ number_of_records: not_null + > 0

**Testes em Nível de Tabela**:
- ✅ recency (dados < 7 dias)
- ✅ total_ad_cost > 0 (sem zeros)
- ✅ number_of_records > 0 (sem registros vazios)

**Total**: 14 testes

---

## 🧪 TESTES CUSTOMIZADOS (tests/*.sql)

### 1. test_fct_foreign_keys_integrity.sql
**Objetivo**: Garantir integridade referencial completa

Verifica que:
- Todos os campaign_sk existem em dim_campaigns
- Todos os date_sk existem em dim_dates
- Todos os platform_sk existem em dim_platforms

**Severidade**: ERROR (falha a build)

---

### 2. test_fct_no_duplicates.sql
**Objetivo**: Prevenir duplicatas na tabela fato

Verifica que:
- Combinação (campaign_sk, date_sk, platform_sk) é única
- Máximo 1 linha por campanha/data/plataforma

**Severidade**: ERROR (falha a build)

---

### 3. test_negative_costs.sql
**Objetivo**: Detectar valores negativos (erro de ETL)

Verifica que:
- ad_cost >= 0 em todas as staging tables
- Identifica qual plataforma tem erro se encontrado

**Severidade**: ERROR (falha a build)

---

### 4. test_future_dates.sql
**Objetivo**: Prevenir dados futuros (integridade temporal)

Verifica que:
- ad_date <= current_date() em todas as staging tables
- Identifica qual plataforma e quantos registros futuros

**Severidade**: ERROR (falha a build)

---

### 5. test_expected_platforms.sql
**Objetivo**: Validar cadastro de plataformas

Verifica que:
- Exatamente 3 plataformas existem (Google, Facebook, TikTok)
- Nenhuma plataforma extra ou faltante
- Previne dados órfãos ou configuração incorreta

**Severidade**: ERROR (falha a build)

---

## 📈 RESUMO GERAL

| Tipo | Quantidade |
|------|-----------|
| **Genérico (unique)** | 6 |
| **Genérico (not_null)** | 35+ |
| **Genérico (accepted_values)** | 3 |
| **Genérico (relationships)** | 3 |
| **Genérico (expression_is_true)** | 8+ |
| **Genérico (not_null_proportion)** | 1 |
| **Genérico (recency)** | 1 |
| **Customizado (SQL)** | 5 |
| **TOTAL** | **62+** |

---

## 🚀 COMO RODAR OS TESTES

### Rodar Todos os Testes
```bash
dbt test
```

**Saída Esperada**:
```
Executed 62 tests, 0 failures
```

### Rodar Testes de Um Modelo
```bash
dbt test --select fct_campaign_performance
dbt test --select dim_campaigns
dbt test --select stg_google_ads
```

### Rodar Testes Customizados Específicos
```bash
dbt test --select test_fct_no_duplicates
dbt test --select test_negative_costs
```

### Rodar Testes com Output Detalhado
```bash
dbt test --verbose
```

### Rodar Testes Ignorando Falhas (para debug)
```bash
dbt test --fail-fast false
```

---

## ⚠️ FALHAS COMUNS E COMO DEBUGGAR

### Falha: "not_null" em ad_cost
```
Motivo: JSON não estava sendo parseado corretamente
Solução: Verificar sintaxe de extração JSON no Snowflake
```

### Falha: "relationships" em campaign_sk
```
Motivo: Surrogate key não gerada corretamente
Solução: Verificar se dbt_utils foi instalado (dbt deps)
```

### Falha: "unique" em raw_id
```
Motivo: Fivetran ingeriu duplicatas da API
Solução: Investigar logs do Fivetran, fazer reload
```

### Falha: test_fct_foreign_keys_integrity
```
Motivo: dim_campaigns faltam registros
Solução: Verificar se int_all_ads_campaigns está rodando completamente
```

---

## 🎯 BOAS PRÁTICAS

✅ Rode `dbt test` antes de fazer push  
✅ Resolva testes AMARELOS (warnings) dentro de 24h  
✅ Resolva testes VERMELHOS (errors) imediatamente  
✅ Documente por que um teste foi removido, se algum dia for  
✅ Adicione novos testes para novos campos/modelos  

---

**Último Update**: Março 2026  
**Maintainer**: Analytics Engineering Team
