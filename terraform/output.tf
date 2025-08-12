output "db_endpoint" {
  value = aws_db_instance.blendergrid_db.endpoint
}

output "db_port" {
  value = aws_db_instance.blendergrid_db.port
}
