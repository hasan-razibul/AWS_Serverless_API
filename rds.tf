resource "random_id" "this" {
  byte_length = 8
}

resource "random_string" "db_username" {
  length  = 16
  special = false
}
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "api_database" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.4.0"

  identifier = "api-database-${var.db_name}-${random_id.this.hex}"
  engine               = var.engine
  family               = var.db_family
  major_engine_version = var.major_engine_version
  instance_class       = "db.t3.micro"
  publicly_accessible  = true
  ca_cert_identifier   = "rds-ca-rsa4096-g1"
  allocated_storage     = "8"
  max_allocated_storage = "50"
  db_name  = var.db_name
  username = random_string.db_username.result
  port     = "5432"
  password = random_password.db_password.result
  manage_master_user_password = false
  multi_az               = false
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  maintenance_window              = "Sun:00:00-Sun:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  skip_final_snapshot     = true
  deletion_protection     = false
  storage_encrypted       = true
}

resource "aws_security_group" "db_security_group" {
  name        = "${var.db_name}-sg"
  description = "Allow postgres"
}

resource "aws_security_group_rule" "db_security_group_rule" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.db_security_group.id
}