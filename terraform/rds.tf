resource "aws_db_instance" "blendergrid_db" {
  identifier            = "blendergrid-on-rails"
  engine                = "postgres"
  engine_version        = "15.4"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = "blendergrid"
  username = "postgres"
  password = var.db_password

  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = { Name = "Blendergrid on Rails Database" }
}

resource "aws_security_group" "rds" {
  name_prefix = "blendergrid-rds-"
  description = "Security group for Blendergrid RDS instance"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PostgreSQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Blendergrid RDS Security Group"
  }
}
