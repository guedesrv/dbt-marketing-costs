with fb as (
    select * from {{ ref('stg_facebook_ads') }}
),
gg as (
    select * from {{ ref('stg_google_ads') }}
),
tk as (
    select * from {{ ref('stg_tiktok_ads') }}
),
unioned as (
    select * from fb
    union all
    select * from gg
    union all
    select * from tk
)
select 
    -- Criação de uma Surrogate Key (SK) garantindo unicidade cruzada
    md5(platform || '-' || campaign_id) as campaign_sk,
    *
from unioned
