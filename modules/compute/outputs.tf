output "ecr_repository_url" {
  value = aws_ecr_repository.fastapi_app.repository_url
}

output "ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}
