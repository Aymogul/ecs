output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "Open this DNS name in a browser after terraform apply completes."
}

output "ecs_cluster_name" {
  value       = module.ecs.ecs_cluster_name
  description = "Created ECS cluster name."
}

output "ecs_service_name" {
  value       = module.ecs.ecs_service_name
  description = "Created ECS service name."
}
