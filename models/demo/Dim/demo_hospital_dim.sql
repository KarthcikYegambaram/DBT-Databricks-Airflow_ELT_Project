{{ config(materialized='table') }}

with hospital as (
    select distinct
        hospital_id,
        hospital_name,
        {{generate_md5_hash(['hospital_id','hospital_name'])}} as hospital_hk
    from {{ ref('stg_clinical') }}
) select * from hospital