{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'hospital_hk'
) }}

{% if not is_incremental() %}

-- =========================================================
-- INITIAL LOAD
-- Insert all records as current (ACTIVE)
-- =========================================================

select distinct
    hospital_id,
    hospital_name,

    -- Version-level hash key
    {{ generate_md5_hash([
        'hospital_id',
        'hospital_name'
    ]) }} as hospital_hk,

    current_timestamp() as start_date,
    cast(null as timestamp) as end_date,
    'yes' as active

from {{ ref('stg_clinical') }}

{% else %}

-- =========================================================
-- INCREMENTAL LOAD (SCD TYPE 2)
-- =========================================================

with source as (

    -- 1. Latest source snapshot with version hash
    select distinct
        hospital_id,
        hospital_name,

        {{ generate_md5_hash([
            'hospital_id',
            'hospital_name'
        ]) }} as hospital_hk

    from {{ ref('stg_clinical') }}

),

current_dim as (

    -- 2. Currently ACTIVE hospital records
    select
        *
    from {{ this }}
    where active = 'yes'

),

changes as (

    -- 3. New hospitals OR changed attributes
    select
        s.hospital_hk,
        s.hospital_id,
        s.hospital_name,
        current_timestamp() as start_date,
        cast(null as timestamp) as end_date,
        'yes' as active
    from source s
    left join current_dim d
        on s.hospital_id = d.hospital_id
    where d.hospital_id is null
       or s.hospital_hk <> d.hospital_hk

),

closed_old as (

    -- 4. Close old versions for changed hospitals
    select
        d.hospital_hk,
        d.hospital_id,
        d.hospital_name,
        d.start_date,
        current_timestamp() as end_date,
        'no' as active
    from current_dim d
    join changes c
        on d.hospital_id = c.hospital_id

),

unchanged as (

    -- 5. Keep unchanged current records untouched
    select
        d.hospital_hk,
        d.hospital_id,
        d.hospital_name,
        d.start_date,
        d.end_date,
        d.active
    from current_dim d
    left join changes c
        on d.hospital_id = c.hospital_id
    where c.hospital_id is null

)

-- =========================================================
-- FINAL DATASET PASSED TO MERGE
-- =========================================================

select * from unchanged
union all
select * from closed_old
union all
select * from changes

{% endif %}
