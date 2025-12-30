{{ config(materialized = 'view') }}

with src as (
    select
        product_id,
        product_name
    from {{ source('scd', 'scd_raw') }}
)

select *
from src