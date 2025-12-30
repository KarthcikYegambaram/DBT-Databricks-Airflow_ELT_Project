{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'doctor_hk'
) }}

{% if not is_incremental() %}

-- =========================================================
-- INITIAL LOAD
-- Insert all records as current (ACTIVE)
-- =========================================================

select distinct
    doctor_id,
    doctor_name,

    -- Version-level hash key
    {{ generate_md5_hash([
        'doctor_id',
        'doctor_name'
    ]) }} as doctor_hk,

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
        doctor_id,
        doctor_name,

        {{ generate_md5_hash([
            'doctor_id',
            'doctor_name'
        ]) }} as doctor_hk

    from {{ ref('stg_clinical') }}

),

current_dim as (

    -- 2. Currently ACTIVE dimension records
    select
        *
    from {{ this }}
    where active = 'yes'

),

changes as (

    -- 3. New doctors OR changed attributes
    select
        s.doctor_hk,
        s.doctor_id,
        s.doctor_name,
        current_timestamp() as start_date,
        cast(null as timestamp) as end_date,
        'yes' as active
    from source s
    left join current_dim d
        on s.doctor_id = d.doctor_id
    where d.doctor_id is null
       or s.doctor_hk <> d.doctor_hk

),

closed_old as (

    -- 4. Close old versions for changed doctors
    select
        d.doctor_hk,
        d.doctor_id,
        d.doctor_name,
        d.start_date,
        current_timestamp() as end_date,
        'no' as active
    from current_dim d
    join changes c
        on d.doctor_id = c.doctor_id

),

unchanged as (

    -- 5. Keep unchanged current records untouched
  select 
        d.doctor_hk,
        d.doctor_id,
        d.doctor_name,
        d.start_date,
        d.end_date,
        d.active
        from current_dim d left join changes c 
        on d.doctor_id = c.doctor_id
        where c.doctor_id is null 
        

)

-- =========================================================
-- FINAL DATASET PASSED TO MERGE
-- =========================================================

select
    doctor_hk,
    doctor_id,
    doctor_name,
    start_date,
    end_date,
    active
from unchanged

union all

select
    doctor_hk,
    doctor_id,
    doctor_name,
    start_date,
    end_date,
    active
from closed_old

union all

select
    doctor_hk,
    doctor_id,
    doctor_name,
    start_date,
    end_date,
    active
from changes

{% endif %}
