{{ config(materialized='table') }}


select
    d.doctor_hk,
    h.hospital_hk,
    p.patient_hk,
    s.admission_date,
    s.discharge_date,
    datediff(s.discharge_date, s.admission_date) as length_of_stay,
    s.diagnosis_code
from {{ ref('stg_clinical') }} s
left join {{ ref('demo_doctor_dim') }} d 
    on s.doctor_id = d.doctor_id
left join {{ ref('demo_hospital_dim') }} h 
    on s.hospital_id = h.hospital_id
left join {{ ref('demo_patient_dim') }} p 
    on s.patient_id = p.patient_id
