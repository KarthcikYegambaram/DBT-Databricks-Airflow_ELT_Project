with source as (
    select *
    from {{ source('raw', 'clinical_raw') }}
)
select
    patient_id,
    first_name,
    last_name,
    dob,
    gender,
    diagnosis_code,
    admission_date,
    discharge_date,
    doctor_id,
    doctor_name,
    hospital_id,
    hospital_name
from source
