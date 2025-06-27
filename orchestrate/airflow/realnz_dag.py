import datetime
from airflow import models
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.operators.python import PythonOperator
from airflow.sensors.external_task import ExternalTaskSensor
from airflow.models import Variable
import pendulum
from kubernetes.client import models as k8s_models
from copy import deepcopy
from airflow.config_templates.airflow_local_settings import DEFAULT_LOGGING_CONFIG
import sys
import logging
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
import json
import time
from datetime import timedelta,datetime, timezone
import datetime
from google.cloud import secretmanager
from google.cloud import storage 
from airflow.operators.dagrun_operator import TriggerDagRunOperator
from google.cloud import storage
import json


IMAGE = "australia-southeast1-docker.pkg.dev/real-nz-main/meltano/meltano-realnz-main:prod"


log: logging.log = logging.getLogger("airflow.task")
log.setLevel(logging.INFO)

local_tz = pendulum.timezone("Pacific/Auckland")
yesterday = datetime.datetime.now(local_tz) - datetime.timedelta(days=1)
ga4_start_date = datetime.datetime.now(local_tz) - datetime.timedelta(days=30)
default_args = {
    "retries": 3,
    "max_active_runs": 1,
    "concurrency": 1,
    "catchup": False,
    "start_date": yesterday
}
dv360_args = {
    "retries": 2,
    "retry_delay": datetime.timedelta(minutes=3),
    "start_date": yesterday,
    "catchup": False,
    "concurrency": 1,
    "max_active_runs": 1
}

# Setting timezone for DAG's start date
start_date = datetime.datetime(2024, 1, 1, tzinfo=local_tz)
start_date_str = start_date.strftime("%Y-%m-%d")
start_date_str = yesterday.strftime("%Y-%m-%d")
ga4_start_date_str = ga4_start_date.strftime("%Y-%m-%d")
def get_meltano_env():
    # Update meltano_env with dynamic dates
    meltano_env_unique = Variable.get("meltano_realnz_main", deserialize_json=True)
    meltano_env_common = Variable.get("meltano_common_secret",deserialize_json=True)
    meltano_env = {**meltano_env_common, **meltano_env_unique}
    meltano_env["START_DATE"] = start_date_str
    meltano_env["BQ_METHOD"] = "batch_job"
    meltano_env_copy = deepcopy(meltano_env)
    return meltano_env_copy

with models.DAG(
    dag_id="realnz-meltano-extraction-transformation-dbt",
    schedule_interval="0 4 * * *",
    default_args=default_args,
) as dag:
    def set_env_vars_hivestack(id,label):
        env = get_meltano_env()
        env["BQ_DATASET"] = f"hivestack_raw__{label}"
        env["BQ_METHOD"] = "batch_job"
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'hivestack_transformed__{label}'
        env["TAP_HIVESTACK_REPORT_ID"] = id
        return env
    def set_env_vars_ga4(id,label):
        env = get_meltano_env()
        env["BQ_DATASET"] = f"ga4_raw__{label}"
        env["BQ_METHOD"] = "gcs_stage"
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'ga4_transformed__{label}'       
        developer_creds = Credentials(
            None,
            refresh_token=env["TAP_GA4_OAUTH_CREDENTIALS_REFRESH_TOKEN"],
            token_uri="https://oauth2.googleapis.com/token",
            client_id=env["TAP_GA4_OAUTH_CREDENTIALS_CLIENT_ID"],
            client_secret=env["TAP_GA4_OAUTH_CREDENTIALS_CLIENT_SECRET"],
        )
        developer_creds.refresh(Request())
        env["TAP_GA4_OAUTH_CREDENTIALS_ACCESS_TOKEN"] = developer_creds.token
        env["TAP_GA4_PROPERTY_ID"] = id
        env["TAP_GA4_START_DATE"] = ga4_start_date_str
        return env
    def set_env_vars_facebook(account_id,value):
        env = get_meltano_env()
        env["BQ_DATASET"] = f"facebook_raw__{value}"
        env["BQ_METHOD"] = "batch_job"
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'facebook_transformed__{value}'
        env["TAP_FACEBOOK_ACCOUNT_ID"] = account_id
        env["TAP_FACEBOOK_AIRBYTE_CONFIG_ACCOUNT_ID"] = account_id
        return env
    def set_env_vars_cm360(value):
        env = get_meltano_env()
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'cm360_transformed__{value}'
        return env
    def set_env_vars_dv360(account_id,value):
        env = get_meltano_env()
        env["BQ_DATASET"] = f"dv360_raw__{value}"
        env["BQ_METHOD"] = "batch_job"
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'dv360_transformed__{value}'
        env["TAP_DV360_ADVERTISER_ID"] = account_id
        return env

    def set_env_vars_ttd(key,value):
        env = get_meltano_env()
        env["BQ_DATASET"] = f"ttd_raw__{value}"
        env["BQ_METHOD"] = "batch_job"
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'ttd_transformed__{value}'
        env["TAP_TTD_ADVERTISER_ID"] = key
        return env
    def set_env_vars_google_ads(value):
        env = get_meltano_env()
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'google_ads_dv_transformed__{value}'
        return env

    def set_env_vars_dash(value):
        env = get_meltano_env()
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'dash_table__{value}'
        return env
    def set_env_vars_tiktok(id,value):
        env = get_meltano_env()
        env["BQ_DATASET"] = f"tiktok_raw__{value}"
        env["BQ_METHOD"] = "batch_job"
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'tiktok_transformed__{value}'
        env['TIKTOK_AIRBYTE_CONFIG_CREDENTIALS_ADVERTISER_ID'] = id
        return env
    def set_env_vars_google_ads_search(value):
        env = get_meltano_env()
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'google_ads_search_transformed__{value}'
        return env
    def set_env_vars_dash_search(value):
        env = get_meltano_env()
        env["DBT_BIGQUERY_METHOD"] = 'oauth'
        env["DBT_BIGQUERY_PROJECT"] = 'real-nz-main'
        env["DBT_BIGQUERY_DATASET"] = f'dash_table_search__{value}'
        return env
    env = get_meltano_env()
    kube_list_dv= []
    kube_list_search=[]
    kube_list_ga4 = []
    kube_dash_dv = []
    kube_dash_table_search = []
    per_label_tasks = {}
    per_label_tasks_search = {}
    hivestack_list = {env["TAP_HIVESTACK_REPORT_ID_MOUNTAIN"]:"mountain", env["TAP_HIVESTACK_REPORT_ID_TOURISM"]:"tourism"}
    for key,label in hivestack_list.items():
        kube_hivestack = KubernetesPodOperator(
            name=f"realnz-hivestack-to-bigquery-{label}",
            task_id=f"realnz_hivestack_to_bigquery_{label}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "run",
                "tap-hivestack",
                "target-bigquery",
                f"dbt-bigquery:hivestack_{label}_models"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_hivestack(key,label)
        )
        kube_list_dv.append(kube_hivestack)
        per_label_tasks.setdefault(label, []).append(kube_hivestack)
    facebook_list = {env['TAP_FACEBOOK_ACCOUNT_ID_MOUNTAIN']:"mountain", env['TAP_FACEBOOK_ACCOUNT_ID_TOURISM']:"tourism"}
    for key,labels in facebook_list.items():
        kube_facebook = KubernetesPodOperator(
            name=f"realnz-facebook-to-bigquery-{labels}",
            task_id=f"realnz_facebook_to_bigquery_{labels}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "run",
                "tap-facebook",
                "target-bigquery",
                f"dbt-bigquery:facebook_{labels}_models"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_facebook(key,labels)
        )
        kube_list_dv.append(kube_facebook)
        per_label_tasks.setdefault(labels, []).append(kube_facebook)
        kube_cm360 = KubernetesPodOperator(
            name=f"realnz-cm360-to-bigquery-{labels}",
            task_id=f"realnz_cm360_to_bigquery_{labels}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "invoke",
                f"dbt-bigquery:cm360_{labels}_models"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_cm360(labels)
        )
        kube_list_dv.append(kube_cm360)
        per_label_tasks.setdefault(labels, []).append(kube_cm360)
        if labels == 'tourism':
            ttd_list = {env["TAP_TTD_TOURISM"]:"tourism"}
            for key,labels in ttd_list.items():
                kube_ttd = KubernetesPodOperator(
                    name=f"realnz-ttd-to-bigquery-{labels}",
                    task_id=f"realnz-ttd_to_bigquery_{labels}",
                    namespace="composer-user-workloads",
                    image=IMAGE,
                    arguments=["--environment=prod", "run", "tap-ttd", "target-bigquery",f"dbt-bigquery:ttd_{labels}_models"],
                    container_resources=k8s_models.V1ResourceRequirements(
                        limits={"memory": "1000M", "cpu": "500m"},
                    ),
                    env_vars=set_env_vars_ttd(key,labels),
                    
                )
            kube_cm360 >> kube_ttd
            kube_list_dv.append(kube_ttd)
            per_label_tasks.setdefault(labels, []).append(kube_ttd)
            
    dv360_list = {env['TAP_DV360_ACCOUNT_ID_MOUNTAIN']:"mountain",env['TAP_DV360_ACCOUNT_ID_TOURISM']:"tourism"}
    for key,labels in dv360_list.items():
        kube_dv360 = KubernetesPodOperator(
            name=f"realnz-dv360-to-bigquery-{labels}",
            task_id=f"realnz_dv360_to_bigquery_{labels}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "run",
                "tap-dv360",
                "target-bigquery",
                f"dbt-bigquery:dv360_{labels}_models"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_dv360(key,labels)
        )
        kube_list_dv.append(kube_dv360)
        per_label_tasks.setdefault(labels, []).append(kube_dv360)
        kube_google_ads_search = KubernetesPodOperator(
            name=f"realnz-google-ads-search-to-bigquery-{labels}",
            task_id=f"realnz_google_ads_search_to_bigquery_{labels}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "invoke",
                "dbt-bigquery","run","--select",f"google_ads_search_{labels}"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_google_ads_search(labels)
        )
        kube_list_search.append(kube_google_ads_search)
        per_label_tasks_search.setdefault(labels, []).append(kube_google_ads_search)
        
    ga4_list = {env["TAP_GA4_PROPERTY_ID_MOUNTAIN"]:"mountain",env["TAP_GA4_PROPERTY_ID_TOURISM"]:"tourism"}
    for key,labels in ga4_list.items():
        kube_ga4 = KubernetesPodOperator(
            name=f"realnz-ga4-to-bigquery-{labels}",
            task_id=f"realnz_ga4_to_bigquery_{labels}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "run",
                "tap-ga4",
                "target-bigquery",
                f"dbt-bigquery:ga4_{labels}_models"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_ga4(key,labels),
        )
        kube_list_ga4.append(kube_ga4)
        per_label_tasks.setdefault(labels, []).append(kube_ga4)
        
    tiktok_list = {env["TAP_TIKTOK_AIRBYTE_CONFIG_CREDENTIALS_ADVERTISER_ID_MOUNTAIN"]:"mountain"}
    for key,labels in tiktok_list.items():
        kube_tiktok = KubernetesPodOperator(
            name=f"realnz-tiktok-to-bigquery-{labels}",
            task_id=f"realnz_tiktok_to_bigquery_{labels}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=[
                "--environment=prod",
                "run",
                "tap-tiktok",
                "target-bigquery",
                f"dbt-bigquery:tiktok_{labels}_models"
            ],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_tiktok(key,labels),
        )
        kube_list_dv.append(kube_tiktok)
        per_label_tasks.setdefault(labels, []).append(kube_tiktok)
    google_ads_list = ["realnz"]
    for label in google_ads_list:
        kube_google_ads = KubernetesPodOperator(
            name=f"realnz-google-ads-to-bigquery-{label}",
            task_id=f"realnz-google_ads_to_bigquery_{label}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=["--environment=prod", "invoke", "dbt-bigquery", "run", "--select", f"google_ads_dv__{label}"],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_google_ads(label),
        
        )
        kube_list_dv.append(kube_google_ads)
        per_label_tasks.setdefault(label, []).append(kube_google_ads)
    dash_list = ["mountain","tourism"]
    for label in dash_list:
        kube_dash = KubernetesPodOperator(
            name=f"realnz-dash-to-bigquery-{label}",
            task_id=f"realnz-dash_to_bigquery_{label}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=["--environment=prod", "invoke", "dbt-bigquery", "run", "--select", f"dash_table__{label}"],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_dash(label),
        
        )
        for upstream_task in per_label_tasks.get(label, []):
            upstream_task>>kube_dash
        
    dash_search_list = ["mountain","tourism"]
    for label in dash_search_list:
        kube_dash_search = KubernetesPodOperator(
            name=f"realnz-dash-search-to-bigquery-{label}",
            task_id=f"realnz-dash_search_to_bigquery_{label}",
            namespace="composer-user-workloads",
            image=IMAGE,
            arguments=["--environment=prod", "invoke", "dbt-bigquery", "run", "--select", f"dash_table_search__{label}"],
            container_resources=k8s_models.V1ResourceRequirements(
                limits={"memory": "1000M", "cpu": "500m"},
            ),
            env_vars=set_env_vars_dash_search(label),
        
        )
        for upstream_task in per_label_tasks_search.get(label, []):
            upstream_task>>kube_dash_search

    kube_list_ga4