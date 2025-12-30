{{ config(materialized='table') }}

with Doctor as (
    select distinct
        doctor_id,
        doctor_name,
        {{generate_md5_hash(['doctor_id','doctor_name']) }}as doctor_hk

    from {{ ref('stg_clinical') }}

) select * from doctor


