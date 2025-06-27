import datetime
import logging
import pendulum
from google.cloud import secretmanager
import json
log = logging.getLogger("airflow.task")
log.setLevel(logging.INFO)

# Set timezone
local_tz = pendulum.timezone("Pacific/Auckland")
yesterday = datetime.datetime.now(local_tz) - datetime.timedelta(days=1)
start_date = datetime.datetime(2024, 1, 1, tzinfo=local_tz)

def load_json_secret(secret_name: str, project_id: str) -> dict:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
    response = client.access_secret_version(name=name)
    payload = response.payload.data.decode("UTF-8")
    return json.loads(payload)

def get_merged_meltano_env(project_id: str) -> dict:
    project_secret = "airflow-variables-meltano_uowaikato_main"
    common_secret = "airflow-variables-meltano_common_secret"
    project_env = load_json_secret(project_secret, project_id)
    common_env = load_json_secret(common_secret, project_id)
    # Merge with priority to project_env
    return {**common_env, **project_env}

# Example usage
PROJECT_ID = "739679429225"  # Replace with your actual GCP project ID
merged_env = get_merged_meltano_env(PROJECT_ID)
print(merged_env)
