resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_password" "db_redis_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "repository_ssh_key" {
  name                    = "github-ssh-key-v1"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "db_redis_password" {
  name                    = "db-redis-password-v1"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "repository_ssh_key_secret_string" {
  secret_id     = aws_secretsmanager_secret.repository_ssh_key.id
  secret_string = tls_private_key.ssh_key.private_key_pem
}

resource "aws_secretsmanager_secret_version" "redis_password_secret_string" {
  secret_id = aws_secretsmanager_secret.db_redis_password.id
  secret_string = jsonencode({
    db_redis_password = random_password.db_redis_password.result
  })
}
