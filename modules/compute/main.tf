# ==========================================
# 0. 運算模組輸入變數插槽 (Variables)
# ==========================================
variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "rds_endpoint" { type = string }
variable "rds_db_name" { type = string }
variable "rds_username" { type = string }
variable "rds_password" { type = string }

# ==========================================
# 4. 安全組防火牆 (Security Groups)
# ==========================================
resource "aws_security_group" "alb_sg" {
  name   = "isaac-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Isaac-ALB-SG" }
}

resource "aws_security_group" "ecs_sg" {
  name        = "isaac-ecs-tasks-sg"
  description = "allow inbound traffic to fastapi container"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "Isaac-ECS-SG" }
}

# ==========================================
# 5. Application Load Balancer & Target Group
# ==========================================
resource "aws_lb" "logistics_alb" {
  name               = "isaac-logistics-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  tags               = { Name = "Isaac-Logistics-ALB" }
}

resource "aws_lb_target_group" "web_tg" {
  name        = "isaac-web-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "80"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
  }
}

resource "aws_lb_listener" "http_listener_v2" {
  load_balancer_arn = aws_lb.logistics_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ==========================================
# 6. AWS ECR Repository
# ==========================================
resource "aws_ecr_repository" "fastapi_app" {
  name                 = "isaac-fastapi-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = { Name = "isaac-fastapi-repo" }
}

# ==========================================
# 7. AWS ECS FARGATE DEPLOYMENT
# ==========================================
resource "aws_ecs_cluster" "main" {
  name = "isaac-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "isaac-fastapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "fastapi-container"
      image     = "${aws_ecr_repository.fastapi_app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        { name = "DB_HOST", value = var.rds_endpoint },
        { name = "DB_NAME", value = var.rds_db_name },
        { name = "DB_USER", value = var.rds_username },
        { name = "DB_PASSWORD", value = var.rds_password }
      ]
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "isaac-fastapi-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "fastapi-container"
    container_port   = 80
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "isaac-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
