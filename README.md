# POC Project for a Pharma Client using DBT-Databricks-Airflow

1. Project Overview
Business Scenario

A pharma client wants to modernize its analytics platform for:

Sales performance tracking
Prescription trends
Territory-wise revenue analysis
Product and physician analytics
Compliance reporting
Near real-time reporting

The client currently receives:

CSV files from ERP/CRM systems
Daily prescription feeds
Sales representative data
Product master data
Physician reference data

The goal is to build:

A scalable Medallion Lakehouse architecture
Automated ETL/ELT pipelines
Incremental transformations
SCD Type 2 dimensions
Data quality testing
Orchestration and monitoring

2. Tech Stack
Layer	Technology
Storage	Delta Lake
Compute	Databricks
Transformation	dbt
Orchestration	Apache Airflow
Data Format	Delta Tables
CI/CD	GitHub + Databricks Repos
Monitoring	Airflow Logs + dbt Tests
Reporting	Power BI
Cloud	Microsoft Azure

3. End-to-End Architecture
Raw Data -- Databricks source location
Raw_Layer --- staging DBT Folder
Silver_Layer -- marts DBT Folder
Gold_layer -- Databricks Target Location

Airflow -- to run dbt commands daily 

