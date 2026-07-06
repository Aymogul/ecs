output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "Temporal ECS cluster name."
}

output "service_name" {
  value       = aws_ecs_service.this.name
  description = "Temporal ECS service name."
}

output "ui_dns_name" {
  value       = aws_lb.ui.dns_name
  description = "Temporal UI load balancer DNS name."
}

output "database_endpoint" {
  value       = aws_db_instance.this.address
  description = "Temporal PostgreSQL endpoint."
}
