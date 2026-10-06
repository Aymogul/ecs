output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Open this DNS name in a browser after terraform apply completes."
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.app.name
  description = "Created ECS cluster name."
}

output "app_service_name" {
  value       = aws_ecs_service.app.name
  description = "Created public application ECS service."
}

output "worker_service_name" {
  value       = aws_ecs_service.worker.name
  description = "Created private Temporal worker ECS service."
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "Repository to which the application image is published."
}

output "temporal_cloud_address_secret_arn" {
  value       = aws_secretsmanager_secret.temporal_address.arn
  description = "Secret containing the Temporal Cloud gRPC endpoint."
}
