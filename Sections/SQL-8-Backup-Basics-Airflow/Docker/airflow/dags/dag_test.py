from airflow.models import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.empty import EmptyOperator

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
    'PG_Test',
    default_args=default_args,
    description='An Daily Dag for Clean Up Docker Tem Files',
    schedule_interval=timedelta(days=1),
    start_date=pendulum.today("UTC").subtract(hours=20),
    tags=['Postgres', 'Backups']
    
)





t1 = EmptyOperator(task_id="test_empty_task1", dag=dag)
t2 = EmptyOperator(task_id="test_empty_task2", dag=dag)


t1 >> t2

