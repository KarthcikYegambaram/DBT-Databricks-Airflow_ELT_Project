{{ config(materialized='table') }}

with patient as (
    select distinct
        patient_id,
        first_name,
        last_name,
        dob,
        gender,
        {{generate_md5_hash(['patient_id','first_name','last_name','dob','gender'])}} as patient_hk
    from {{ ref('stg_clinical') }}
) select * from patient 
