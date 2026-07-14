output "rds_endpoint" {
  value = aws_db_instance.postgres.address
}

output "rds_password" {
  value     = random_password.rds_password.result
  sensitive = true
}

output "rds_db_name" {
  value = aws_db_instance.postgres.db_name
}

output "rds_username" {
  value = aws_db_instance.postgres.username
}
