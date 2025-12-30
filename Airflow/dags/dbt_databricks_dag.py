from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.dates import days_ago
from airflow.models.param import Param

# DAG definition
with DAG(
    dag_id='dynamic_dbt_runner',
    description='Run dbt dynamically with folders, targets, and full-refresh',
    start_date=days_ago(1),
    schedule_interval=None,  # Manual or trigger-based
    catchup=False,
    params={
        "dbt_folder": Param("/opt/airflow/dbt", type="string"),  # default dbt project folder
        "dbt_target": Param("dev", type="string"),                # default target
        "full_refresh": Param(False, type="boolean"),            # full-refresh option
        "models": Param(None, type="string"),                    # specific models/folders
    }
) as dag:

    # Construct dbt command dynamically
    dbt_run_command = """
    cd {{ params.dbt_folder }} && \
    dbt run \
    {% if params.models %} --select {{ params.models }} {% endif %} \
    --target {{ params.dbt_target }} \
    {% if params.full_refresh %} --full-refresh {% endif %}
    """

    run_dbt = BashOperator(
        task_id='run_dbt',
        bash_command=dbt_run_command
    )

