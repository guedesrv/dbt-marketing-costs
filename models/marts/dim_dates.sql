-- ============================================================================
-- Modelo: dim_dates.sql
-- Camada: Marts
-- Tipo: Table
-- Descrição:
--   Dimensão de calendário para análises temporais.
--   Gera um intervalo de datas baseado nos dados de ads históricos e futuros.
--
-- Regras de Negócio:
--   - Uma linha = um dia do calendário
--   - Inclui atributos úteis para análises (year, month, week, day_of_week)
--   - Intervalo: MIN(ad_date) até MIN(ad_date) + 2 anos (customizável)
--
-- Saída de colunas:
--   date_sk, full_date, year, month, week, day_of_week, day_name, 
--   is_weekend, is_holiday
-- ============================================================================

with date_range as (
    -- Define o intervalo de datas a partir dos dados de ads históricos
    select
        dateadd(
            day,
            seq4(),
            (select min(ad_date) from {{ ref('int_all_ads_campaigns') }})
        ) as full_date
    from table(generator(rowcount => 730))  -- 2 anos de datas
    where full_date is not null
),

dates_with_attributes as (
    -- Enriquece cada data com atributos úteis para análises
    select
        {{ dbt_utils.generate_surrogate_key(['full_date']) }} as date_sk,
        full_date,
        year(full_date) as year,
        month(full_date) as month,
        weekofyear(full_date) as week,
        dayofweek(full_date) as day_of_week,
        dayname(full_date) as day_name,
        case
            when dayofweek(full_date) >= 6 then true
            else false
        end as is_weekend,
        false as is_holiday  -- Pode ser expandido com dados reais de feriados
    from date_range
),

final as (
    select
        date_sk,
        full_date,
        year,
        month,
        week,
        day_of_week,
        day_name,
        is_weekend,
        is_holiday,
        current_timestamp() as dbt_created_at,
        current_timestamp() as dbt_updated_at
    from dates_with_attributes
)

select * from final
