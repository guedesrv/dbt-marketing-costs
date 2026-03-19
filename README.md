# 📊 Marketing Analytics dbt Project

**Uma arquitetura profissional de engenharia de dados para análise centralizada de custos de marketing**, transformando dados JSON brutos do Fivetran em um modelo estrela pronto para BI.

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura de Dados](#arquitetura-de-dados)
3. [Decisões de Engenharia](#decisões-de-engenharia)
4. [Como Executar](#como-executar)
5. [Estrutura de Modelos](#estrutura-de-modelos)
6. [Lineage & DAG](#lineage--dag)

---

## Visão Geral

### O Problema

Três plataformas de publicidade (Google Ads, Facebook Ads, TikTok Ads) enviam dados para o Snowflake via Fivetran em **formato JSON não normalizado**:

- **Google Ads**: `{"campaign_id": 1, "cost": 150.50, "date": "2023-10-01"}`
- **Facebook Ads**: `{"campaign_id": "A1", "amount_spent": 200.00, "spending_date": "2023-10-01"}`
- **TikTok Ads**: `{"camp_id": "T1", "spend": 50.00, "stat_time": "2023-10-01"}`

**Desafios**:
- Nomes de colunas diferentes por plataforma
- Estruturas JSON variadas requerendo parsing customizado
- Colisão de IDs entre plataformas (múltiplas fontes)
- Formato não ideal para ferramentas de BI (Metabase)

### A Solução

**Um pipeline dbt profissional** que:

✅ Descompacta JSON em formato canonical (staging)  
✅ Consolida dados de múltiplas fontes (intermediate)  
✅ Cria um modelo estrela normalizado (marts)  
✅ Gera surrogate keys para integridade de chaves estrangeiras  
✅ Pronto para consumo no Metabase com testes de qualidade  

---

## Arquitetura de Dados

### Fluxo de Transformação (ELT)

```
┌─────────────────────────────────────────────────────────────┐
│                         Raw Data (Fivetran)                  │
├─────────────────────────────────────────────────────────────┤
│  raw_google_ads (JSON)    raw_facebook_ads (JSON)            │
│  raw_tiktok_ads (JSON)                                       │
└────────┬──────────────────────────────────────┬──────────────┘
         │                                      │
         └──────────────────┬───────────────────┘
                            │ dbt parse JSON + normalize
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     STAGING LAYER (Views)                    │
├─────────────────────────────────────────────────────────────┤
│  stg_google_ads     stg_facebook_ads     stg_tiktok_ads      │
│  (canonical schema)          ↓                               │
│  ├─ raw_id                   └─ All 7 column names          │
│  ├─ campaign_id              canonicalized                  │
│  ├─ campaign_name            (raw_id, synced_timestamp,     │
│  ├─ ad_cost (numeric)        campaign_id, campaign_name,    │
│  ├─ ad_date (date)           ad_cost, ad_date, platform)   │
│  ├─ platform (constant)                                     │
│  └─ synced_timestamp                                        │
└────────────────────┬─────────────────────────────────────────┘
                     │
         dbt UNION ALL + Surrogate Key
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              INTERMEDIATE LAYER (Ephemeral)                  │
├─────────────────────────────────────────────────────────────┤
│  int_all_ads_campaigns                                       │
│  ├─ campaign_sk (MD5 hash)                                   │
│  ├─ raw_id                                                   │
│  ├─ campaign_id, campaign_name                               │
│  ├─ ad_cost, ad_date                                         │
│  ├─ platform                                                 │
│  └─ synced_timestamp                                         │
└────────────────────┬─────────────────────────────────────────┘
                     │
     dbt dimensional modeling (Star Schema)
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
┌──────────────┐ ┌─────────────┐ ┌──────────────┐
│ dim_campaigns│ │ dim_dates   │ │ dim_platforms│
├──────────────┤ ├─────────────┤ ├──────────────┤
│campaign_sk✓  │ │date_sk✓     │ │platform_sk✓  │
│campaign_id   │ │full_date    │ │platform_name │
│campaign_name │ │year, month  │ │description   │
│platform      │ │week, etc    │ └──────────────┘
│timestamps    │ │timestamps   │
└──────────────┘ └─────────────┘
        ▲              ▲              ▲
        │              │              │
        └──────┬───────┴──────┬───────┘
               │              │
               │  Foreign Keys
               │              │
               └──────┬───────┘
                      │
                      ▼
        ┌──────────────────────────────┐
        │  FCT_CAMPAIGN_PERFORMANCE    │
        ├──────────────────────────────┤
        │  campaign_sk ●────→ dim_cam  │
        │  date_sk ●────→ dim_dates    │
        │  platform_sk ●──→ dim_plat   │
        │  total_ad_cost (metric)      │
        │  number_of_records           │
        │  timestamps                  │
        └──────────────────────────────┘
                      │
                      ▼
        ┌──────────────────────────────┐
        │  METABASE DASHBOARDS         │
        │  (BI & Analytics Consumers)  │
        └──────────────────────────────┘
```

---

## Decisões de Engenharia

### 1. **Por que Camada Staging com Parsing JSON?**

Na staging, descompactamos o JSON em colunas usando **funções nativas do Snowflake**:

```sql
-- Extração tipada do JSON
raw_payload:campaign_id::string as campaign_id
raw_payload:cost::numeric(10, 2) as ad_cost
raw_payload:date::date as ad_date
```

**Benefícios**:
- **Legibilidade**: SQL fica claro e documentado
- **Type Safety**: Conversões explícitas evitam surpresas
- **Performance**: Snowflake otimiza parsing JSON eficientemente
- **Maintainability**: Mudanças no JSON schema ficam localizadas

### 2. **Por que Surrogate Keys (campaign_sk)?**

Os IDs de campanha **variam em estrutura e tipo** por plataforma:
- Google: `campaign_id = 1` (inteiro)
- Facebook: `campaign_id = "A1"` (string)
- TikTok: `camp_id = "T1"` (string prefixada diferente)

Criamos um **hash MD5 imutável** combinando `campaign_id + platform`:

```sql
{{ dbt_utils.generate_surrogate_key(['campaign_id', 'platform']) }} as campaign_sk
```

**Benefícios**:
- **Integridade**: Garante unicidade de relacionamentos
- **Performance**: Joins mais rápidos com PKs/FKs tipadas
- **Auditoria**: Histórico completamente rastreável
- **Escalabilidade**: Funciona com múltiplas fonts em crescimento

### 3. **Por que Modelo Estrela (Star Schema)?**

Escolhi o **padrão dimensional de Kimball** com:
- **Fato** (FCT_CAMPAIGN_PERFORMANCE): métricas de custo
- **Dimensões** (DIM_CAMPAIGNS, DIM_DATES, DIM_PLATFORMS): contexto

**Benefícios**:
- **Simplicidade**: Joins simples para BI tools
- **Performance**: Queries rápidas sem agregações complexas
- **Escalabilidade**: Fácil adicionar novas métricas/dimensões
- **Inteligibilidade**: Analistas de negócio entendem naturalmente

### 4. **Por que Views na Staging e Ephemeral na Intermediate?**

| Camada | Tipo | Por quê |
|--------|------|---------|
| **Staging** | View | Reutilizável em múltiplos intermediates; auxilia debugging |
| **Intermediate** | Ephemeral | Não precisa ser materializado; otimiza storage; usado 1x |
| **Marts** | Table | Consumido por Metabase; indexado para performance |

### 5. **Testes de Qualidade**

Cada modelo inclui testes automáticos:

```yaml
tests:
  - unique
  - not_null
  - accepted_values
  - relationships  # Foreign keys
  - dbt_utils.not_null_proportion  # 95%+ preenchido
  - dbt_utils.recency  # Dados recentes (< 7 dias)
```

Roda via `dbt test` antes de deployments.

---

## Como Executar

### Pré-requisitos

- **Snowflake**: Database `analytics`, schema `raw_marketing` com tabelas brutas
- **dbt**: Instalado e configurado (`dbt --version`)
- **Python**: 3.8+ (para dbt-core)

### Configuração Inicial

#### 1. Clone e Entre no Diretório

```bash
cd dbt-marketing-costs
```

#### 2. Configure Ambiente Python

Crie um ambiente virtual Python isolado:

```bash
# Criar ambiente virtual
python3 -m venv venv

# Ativar ambiente (macOS/Linux)
source venv/bin/activate

# Ou no Windows:
# venv\Scripts\activate
```

Instale `dbt-core` e dependências:

```bash
pip install --upgrade pip
pip install dbt-core dbt-snowflake
```

Verifique a instalação:

```bash
dbt --version
python --version
```

Esperado:
```
dbt version: 1.5.0 (ou superior)
Python version: 3.8+
```

#### 3. Configure Credenciais Snowflake

Crie/edite `~/.dbt/profiles.yml`:

```yaml
marketing_analytics:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: your_account_id.sa-east-1  # ex: abc123.us-east-1
      user: your_username
      password: your_password
      # Ou use: private_key_path + private_key_passphrase
      role: transformer_role  # role com permissões DDL
      database: analytics
      schema: analytics_dev
      threads: 4
      client_session_keep_alive: False
```

#### 4. Instale Dependências

```bash
dbt deps
```

Isso instala `dbt-utils` (macro library) definida em `packages.yml`.

#### 5. Crie Schema e Teste Conexão

```bash
dbt debug
```

Esperado: "✓ Connection ok!"

---

### Executar Transformações

#### Opção A: Full Build (Recomendado)

Roda modelos + testes em uma única passada:

```bash
dbt build
```

**Saída esperada**:
```
Running with dbt 1.5.0
Found 9 models, 15 tests, 1 analysis...
Completed successfully

Executed 9 create model statements OK
Executed 15 tests OK
```

#### Opção B: Rodar Modelos Apenas

```bash
dbt run
```

#### Opção C: Rodar Testes Apenas

```bash
dbt test
```

#### Opção D: Rodar Modelo Específico

```bash
dbt run --select stg_google_ads
dbt test --select fct_campaign_performance
```

#### Limpar Artefatos

```bash
dbt clean
```

---

### Visualizar Lineage

```bash
dbt docs generate
dbt docs serve
```

Abre navegador em `http://localhost:8000` com DAG completo.

---

## Estrutura de Modelos

### Diretório

```
models/
├── staging/
│   ├── src_marketing.yml              # Definição das sources
│   ├── stg_google_ads.sql             # Parse JSON Google
│   ├── stg_facebook_ads.sql           # Parse JSON Facebook
│   ├── stg_tiktok_ads.sql             # Parse JSON TikTok
│   └── staging.yml                    # Documentação e testes
│
├── intermediate/
│   └── int_all_ads_campaigns.sql      # UNION + campaign_sk
│
└── marts/
    ├── dim_campaigns.sql               # Dimensão campanhas
    ├── dim_platforms.sql               # Dimensão plataformas
    ├── dim_dates.sql                   # Dimensão calendário
    ├── fct_campaign_performance.sql    # Tabela fato
    └── schema.yml                      # Documentação e testes
```

### Contagem de Modelos

| Camada | Modelos | Tipo | Descrição |
|--------|---------|------|-----------|
| **Staging** | 3 | View | Normalização JSON por plataforma |
| **Intermediate** | 1 | Ephemeral | Consolidação com surrogate keys |
| **Marts** | 4 | Table | Dimensões + Fato (Star Schema) |
| **TOTAL** | **8** | - | Pronto para consumo em BI |

---

## Lineage & DAG

```
                  ┌─ Sources ─────────────────────┐
                  │                               │
        ┌─────────┴──────────┐                   │
        │                    │                   │
        ▼                    ▼                   ▼
    raw_google_ads   raw_facebook_ads    raw_tiktok_ads
        │                    │                   │
        ├─ JSON parse ──────┤                   │
        │  (canonical)      │                   │
        │                   │                   │
        ▼                   ▼                   ▼
   stg_google_ads   stg_facebook_ads    stg_tiktok_ads
        │                    │                   │
        └────────┬───────────┴──────────────────┘
                 │
              UNION ALL
         + Surrogate Key (MD5)
                 │
                 ▼
      int_all_ads_campaigns
                 │
        ┌────────┼────────┐
        │        │        │
        ▼        ▼        ▼
    dim_campaigns  dim_platforms  dim_dates
        │              │              │
        └──────┬───────┴──────┬───────┘
               │              │
               │   Foreign Keys
               │   (relationships)
               │              │
               └──────┬───────┘
                      │
                      ▼
          fct_campaign_performance
                      │
                      ▼
           Metabase (BI Dashboards)
```

---

## 📈 Tabelas Resultantes

### Exemplo: `dim_campaigns`

| campaign_sk | campaign_id | campaign_name | platform |
|-------------|-------------|---------------|----------|
| abc123d456... | 1 | Summer Campaign 2023 | Google Ads |
| def789a012... | A1 | Brand Awareness | Facebook Ads |
| ghi234b567... | T1 | Summer Promo | TikTok Ads |

### Exemplo: `fct_campaign_performance`

| campaign_sk | date_sk | platform_sk | total_ad_cost | number_of_records |
|-------------|---------|-------------|-------|-----------|
| abc123d456... | jkl567c... | xyz123d... | 150.50 | 1 |
| def789a012... | jkl567c... | mno456e... | 200.00 | 2 |
| ghi234b567... | pqr789f... | xyz123d... | 50.00 | 1 |

---

## 🧪 Qualidade de Dados

Rodamos testes automáticos em cada build:

```bash
$ dbt test

Completed successfully

Executed 15 tests, 0 failed.
```

**Testes incluem**:
- `unique`: Chaves primárias sem duplicatas
- `not_null`: Colunas críticas preenchidas
- `accepted_values`: Plataforma in ('Google', 'Facebook', 'TikTok')
- `relationships`: Chaves estrangeiras válidas
- `recency`: Dados não mais velhos que X dias

---

## 🚀 Deployment

### Development

```bash
dbt run --target dev
dbt test --target dev
```

### Production

```bash
dbt build --target prod
```

Adicione em `profiles.yml`:

```yaml
prod:
  type: snowflake
  # ... credenciais prod
  schema: analytics_prod
```

---

## 📝 Camadas de Transformação

### 1. **Staging** (Limpeza)

- Parse JSON em colunas tipadas
- Renomeia para padrão canonical
- Views reutilizáveis
- Testes de unicidade/integridade

### 2. **Intermediate** (Consolidação)

- UNION de múltiplas fontes
- Cria surrogate keys
- Efêmero (não materializado)

### 3. **Marts** (Análises)

- Dimensional modeling (Star Schema)
- Otimizado para BI
- Testes de relacionamentos/integridade
- Pronto para Metabase

---

## 📞 Suporte & Manutenção

### Debug de Modelos

```bash
# Ver SQL compilado
dbt compile
cat target/compiled/marketing_analytics/models/marts/fct_campaign_performance.sql

# Executar modelo específico com output
dbt run --select fct_campaign_performance

# Preview dos dados
dbt docs generate && dbt docs serve  # Ver no browser
```

### Atualizar Mudanças de Schema

Se a estrutura do JSON mudar:

1. Atualize o arquivo de staging relevante
2. Rode `dbt run --select stg_*`
3. Execute `dbt test` para validar

---

## 📚 Referências

- [dbt Documentation](https://docs.getdbt.com/)
- [Snowflake JSON Functions](https://docs.snowflake.com/en/sql-reference/functions/parse_json.html)
- [Kimball Dimensional Modeling](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/)
- [dbt-utils](https://github.com/dbt-labs/dbt-utils)

---

**Última atualização**: Março 2026  
**Autor**: Rodrigo Guedes  
**Versão**: 1.0.0


