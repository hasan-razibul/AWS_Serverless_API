resource "aws_secretsmanager_secret" "db_credentials" {
  name = "api-database-${var.db_name}-admin-credentials-${random_id.this.hex}"
}

resource "aws_secretsmanager_secret_version" "db_pwd_secret_manager" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    db_name       = module.api_database.db_instance_name
    db_username = random_string.db_username.result
    db_password = random_password.db_password.result
  })
}