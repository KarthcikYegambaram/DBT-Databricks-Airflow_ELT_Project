{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = 'admission_hashkey'
) }}

-- =========================================================
-- FACT: ADMISSIONS
-- =========================================================

with source_events as (

    select
        d.doctor_hk,
        h.hospital_hk,
        p.patient_hk,

        s.admission_date,
        s.discharge_date,
        datediff(s.discharge_date, s.admission_date) as length_of_stay,
        s.diagnosis_code,

        --  fact row hash
        {{ generate_md5_hash([
            'd.doctor_id',
            'h.hospital_id',
            'p.patient_id',
            's.admission_date',
            's.discharge_date',
            's.diagnosis_code'
        ]) }} as admission_hashkey,

        current_timestamp() as load_timestamp

    from {{ ref('stg_clinical') }} s

    -- Join ACTIVE doctor version
    left join {{ ref('dim_doctor') }} d
        on s.doctor_id = d.doctor_id
       and d.active = 'yes'

    -- Join ACTIVE hospital version
    left join {{ ref('dim_hospital') }} h
        on s.hospital_id = h.hospital_id
       and h.active = 'yes'

    -- Join ACTIVE patient version
    left join {{ ref('dim_patient') }} p
        on s.patient_id = p.patient_id
       and p.active = 'yes'

)

select 
distinct  admission_hashkey,
    patient_hk,
    doctor_hk,
    hospital_hk,
    admission_date,
    discharge_date,
    length_of_stay,
    diagnosis_code,
    load_timestamp
from source_events
