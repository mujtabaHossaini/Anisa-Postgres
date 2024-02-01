from airflow.models import DAG
from airflow.operators.bash_operator import BashOperator
# from airflow.utils.dates import  
from datetime import timedelta
from airflow.models.pool import Pool
import os, pendulum


default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['mojtaba.banaie@gmail.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=10),
}

dag = DAG(
    'PG_Daily_Backups',
    default_args=default_args,
    description='An Daily Dag for Clean Up Docker Tem Files',
    schedule_interval=timedelta(days=1),
    start_date=pendulum.today("UTC").subtract(hours=20),
    tags=['Postgres', 'Backups']
    
)

pg_daily_schema_backup= BashOperator(
    task_id='pg_daily_schema_backup',
    bash_command="/scripts/daily_schema_backup_script.sh  >> /backups/backup_log.log 2>&1",
    dag=dag
)

pg_daily_schema_backup

