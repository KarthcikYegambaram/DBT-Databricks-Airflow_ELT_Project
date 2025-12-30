FROM apache/airflow:2.9.3-python3.12

USER root

# System dependencies (needed for dbt + databricks)
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    unixodbc-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER airflow

# Upgrade pip
RUN pip install --upgrade pip

# Install dbt for Databricks (CORRECT versions)
RUN pip install \
    dbt-core==1.8.8 \
    dbt-databricks==1.8.7

