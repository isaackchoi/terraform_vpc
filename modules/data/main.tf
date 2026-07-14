variable "vpc_id" { type = string }
variable "ecs_sg_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# ==========================================
# 9. RDS 關聯式資料庫配置 (PostgreSQL)
# ==========================================
resource "aws_security_group" "rds_sg" {
  name        = "isaac-rds-sg"
  description = "Allow DB access from ECS tasks"
  vpc_id      = var.vpc_id # 💡 模組內部：改用變數向總指揮索取 VPC ID

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_sg_id] # 💡 模組內部：改用變數向總指揮索取 ECS 安全組 ID
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Isaac-RDS-SG" }
}

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!@#"
}

resource "aws_db_subnet_group" "rds_subnets" {
  name       = "isaac-rds-subnet-group"
  subnet_ids = var.private_subnet_ids # 💡 模組內部：改用變數向總指揮索取私有子網路 IDs
  tags       = { Name = "isaac-rds-subnet-group" }
}

resource "aws_db_instance" "postgres" {
  identifier             = "isaac-postgres"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  db_name                = "isaacdb"
  username               = "isaac_admin"
  password               = random_password.rds_password.result
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true
  deletion_protection    = false
  tags                   = { Name = "isaac-postgres" }
}
