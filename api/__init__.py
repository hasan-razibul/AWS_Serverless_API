import os
import json
import boto3

def get_secret(secret_name: str) -> str:
        """
        Retrieve individual secrets from AWS Secrets Manager using the get_secret_value API.
        :param secret_name: The name of the secret to retrieve.
        :return: The secret string.
        """
        try:
            client = boto3.client("secretsmanager")
            get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        except Exception as e:
            print(f"Error retrieving secret: {e}")
            raise e
        return get_secret_value_response['SecretString']

db_url = os.environ.get('DB_URL')
db_credentials_secret_name = os.environ.get('DB_CREDENTIALS_SECRETS_NAME')
try:
    db_credentials = json.loads(get_secret(db_credentials_secret_name))
except Exception as e:
    print(f"Error getting DB credentials: {e}")