{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'patient_hk'
) }}

{% if not is_incremental() %}

-- =========================================================
-- INITIAL LOAD
-- Insert all records as current (ACTIVE)
-- =========================================================

select distinct
    patient_id,
    first_name,
    last_name,
    dob,
    gender,

    -- Version-level hash key
    {{ generate_md5_hash([
        'patient_id',
        'first_name',
        'last_name',
        'dob',
        'gender'
    ]) }} as patient_hk,

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
        patient_id,
        first_name,
        last_name,
        dob,
        gender,

        {{ generate_md5_hash([
            'patient_id',
            'first_name',
            'last_name',
            'dob',
            'gender'
        ]) }} as patient_hk

    from {{ ref('stg_clinical') }}

),

current_dim as (

    -- 2. Currently ACTIVE patient records
    select
        *
    from {{ this }}
    where active = 'yes'

),

changes as (

    -- 3. New patients OR changed attributes
    select
        s.patient_hk,
        s.patient_id,
        s.first_name,
        s.last_name,
        s.dob,
        s.gender,
        current_timestamp() as start_date,
        cast(null as timestamp) as end_date,
        'yes' as active
    from source s
    left join current_dim d
        on s.patient_id = d.patient_id
    where d.patient_id is null
       or s.patient_hk <> d.patient_hk

),

closed_old as (

    -- 4. Close old versions for changed patients
    select
        d.patient_hk,
        d.patient_id,
        d.first_name,
        d.last_name,
        d.dob,
        d.gender,
        d.start_date,
        current_timestamp() as end_date,
        'no' as active
    from current_dim d
    join changes c
        on d.patient_id = c.patient_id

),

unchanged as (

    -- 5. Keep unchanged current records untouched
    select
        d.patient_hk,
        d.patient_id,
        d.first_name,
        d.last_name,
        d.dob,
        d.gender,
        d.start_date,
        d.end_date,
        d.active
    from current_dim d
    left join changes c
        on d.patient_id = c.patient_id
    where c.patient_id is null

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
