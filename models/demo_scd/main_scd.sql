{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'product_hashkey'
) }}

{% if not is_incremental() %}

-- =========================================================
-- Insert all records as current (ACTIVE)
-- =========================================================

select distinct
    product_id,
    product_name,

    -- Version-level hash key
    {{ generate_md5_hash([
        'product_id',
        'product_name'
    ]) }} as product_hashkey,

    current_timestamp() as start_date,
    cast(null as timestamp) as end_date,
    'yes' as active

from {{ ref('stg_scd') }}

{% else %}

-- =========================================================
-- INCREMENTAL LOAD (SCD TYPE 2)
-- =========================================================

with source as (

    -- 1. Latest source snapshot with version hash
    select distinct
        product_id,
        product_name,

        {{ generate_md5_hash([
            'product_id',
            'product_name'
        ]) }} as product_hashkey

    from {{ ref('stg_scd') }}

),

current_dim as (

    -- 2. Currently ACTIVE dimension records
    select
        * 
    from {{ this }}
    where active ='yes'

),

changes as (

    -- 3. New products OR changed attributes
    select
        s.product_hashkey,
        s.product_id,
        s.product_name,
        current_timestamp as start_date,
        cast(null as timestamp) as end_date,
        'yes' as active
    from source s
    left join current_dim d
        on s.product_id = d.product_id
    where d.product_id is null
       or s.product_hashkey <> d.product_hashkey

),

closed_old as (

    -- 4. Close old versions for changed products
    select
        d.product_hashkey,
        d.product_id,
        d.product_name,
        d.start_date,
        current_timestamp() as end_date,
        'no' as active
    from current_dim d
    join changes c
        on d.product_id = c.product_id

),

unchanged as (

    -- 5. Keep unchanged current records untouched
    select
        d.product_hashkey,
        d.product_id,
        d.product_name,
        d.start_date,
        d.end_date,
        d.active
    from current_dim d
    left join changes c
        on d.product_id = c.product_id
    where c.product_id is null

)

-- =========================================================
-- FINAL DATASET PASSED TO MERGE


select
    product_hashkey,
    product_id,
    product_name,
    start_date,
    end_date,
    active
from unchanged

union all

select
    product_hashkey,
    product_id,
    product_name,
    start_date,
    end_date,
    active
from closed_old

union all

select
    product_hashkey,
    product_id,
    product_name,
    start_date,
    end_date,
    active
from changes

{% endif %}
