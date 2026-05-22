
🧬 DBT-Databricks-Airflow ELT Project – Pharma Analytics Pipeline
===============================================================================

📌 Project Overview
================================================================================
This project implements an end-to-end ELT pipeline for a pharmaceutical client to modernise their analytics platform. It transforms raw clinical and SCD (Slowly Changing Dimension) data into a clean, business-ready data model using a Medallion Lakehouse architecture (Raw → Silver → Gold). The pipeline is built with:

✅ dbt – transformation logic, incremental models, and SCD Type II
✅ Databricks – Delta Lake storage + SQL compute
✅ Apache Airflow – orchestration of dbt runs
✅ Power BI – reporting layer on Azure

🧪 The current implementation serves as a proof-of-concept (POC) demonstrating incremental processing, SCD Type II, custom macros, and orchestration. It is suitable for learning and portfolio showcases, but requires additional hardening for production.

🏗️ Architecture
================================================================================
🔹 Raw Layer (Bronze/Delta Tables) → 🔹 Silver Layer (dbt staging + SCD) → 🔹 Gold Layer (dbt dimensions/facts) → 📊 Power BI Reporting

🎛️ Orchestration: Apache Airflow

📊 Data Lineage (High Level)
- 📁 Raw tables: clinical_raw, scd_raw
- 👁️ Staging views: stg_clinical, stg_scd
- 🧩 Dimensions: dim_patient (SCD Type II), dim_date (placeholder)
- 📈 Facts: fact_events (placeholder)

📁 Repository Structure
================================================================================
.
├── 📄 dbt_project.yml
├── 🗂️ models/
│   ├── 🗂️ staging/
│   │   ├── 📜 stg_clinical.sql
│   │   └── 📜 stg_scd.sql
│   ├── 🗂️ marts/
│   │   ├── 🗂️ core/
│   │   │   ├── 📜 dim_patient.sql
│   │   │   └── 📜 fact_events.sql
│   │   └── 🗂️ intermediate/
├── 🛠️ macros/
│   ├── 📜 generate_md5_hash.sql
│   └── 📜 log_audit_entry.sql
├── 🧪 tests/                 (empty)
├── 📸 snapshots/             (empty)
├── 📊 analysis/
├── 🐳 docker/
│   ├── 📄 Dockerfile
│   └── 📄 docker-compose.yml
└── 📖 README.md

🚀 Getting Started
================================================================================

📦 Prerequisites
- 🐍 Python 3.9+
- ☁️ Databricks workspace (Community Edition or paid) with SQL Warehouse or Cluster
- 🌬️ Airflow environment (local Docker or managed service)
- 🔧 dbt Core or dbt Cloud

1️⃣ Clone the Repository
--------------------------------------------------------------------------------
git clone https://github.com/KarthcikYegambaram/DBT-Databricks-Airflow_ELT_Project.git
cd DBT-Databricks-Airflow_ELT_Project

2️⃣ Set Up Databricks
--------------------------------------------------------------------------------
- Create a cluster (or use a SQL Warehouse).
- Create a catalog and schema (e.g., pharma_dev.default).
- Upload raw data files (clinical_raw, scd_raw) as Delta tables.

3️⃣ Configure dbt Profile
--------------------------------------------------------------------------------
Create ~/.dbt/profiles.yml with the following content (adjust values):

dbt_databricks_airflow_project:
  target: dev
  outputs:
    dev:
      type: databricks
      host: your-workspace.cloud.databricks.com
      http_path: /sql/1.0/warehouses/your_warehouse_id
      token: your_personal_access_token
      catalog: pharma_dev
      schema: default
      threads: 4

4️⃣ Run dbt Locally
--------------------------------------------------------------------------------
dbt deps
dbt run
dbt test
dbt docs generate && dbt docs serve

5️⃣ Orchestrate with Airflow (Docker)
--------------------------------------------------------------------------------
cd docker
docker-compose up -d
🌐 Airflow UI: http://localhost:8080 (user: airflow, pass: airflow)

🧪 Data Quality & Testing (Current Gaps)
================================================================================
⚠️ The project currently lacks explicit dbt tests. To make it production-ready, add:

- ✅ Generic tests in models/schema.yml (unique, not_null, relationships)
- ✅ Singular tests in tests/ folder
- ✅ Consider dbt-expectations for advanced row-level checks

🔧 Key Implementation Details
================================================================================

🔄 SCD Type II – dim_patient
Uses a merge strategy with an MD5 hash of business key + all attributes to detect changes. When a change occurs:
- 🗑️ Old record gets is_current = false and valid_to = current_timestamp
- ✨ New record gets is_current = true, valid_from = current_timestamp, valid_to = null

⚡ Incremental Models
All dimension and fact models use materialized='incremental' with incremental_strategy='merge' for efficient updates.

🛠️ Custom Macros
- 🔑 generate_md5_hash() – deterministic hash for change detection
- 📝 log_audit_entry() – inserts audit records into a pipeline_audit table

⚠️ Known Limitations & Roadmap
================================================================================
+-------------------------------------+----------+------------------------------------------------+
| Limitation                          | Priority | Planned Fix                                   |
+-------------------------------------+----------+------------------------------------------------+
| ❌ No data quality tests               | 🔴 High   | Add generic + singular tests                  |
| ⏳ Incomplete CDC (near-real-time)     | 🔴 High   | Use Databricks Autoloader or Streaming        |
| 🔐 MD5 for hash keys                   | 🟡 Medium | Migrate to SHA-256                            |
| ⚙️ Missing dbt_project.yml configs     | 🟡 Medium | Add on_schema_change, partitioning, clustering|
| 🎛️ Airflow DAG not included            | 🟡 Medium | Provide example DAG with retries & alerts     |
| 📄 Sparse documentation                | 🔴 High   | Expand README & add inline comments           |
+-------------------------------------+----------+------------------------------------------------+



📬 Contact
================================================================================
👤 Author: Karthcik Yegambaram
🐙 GitHub: @KarthcikYegambaram
