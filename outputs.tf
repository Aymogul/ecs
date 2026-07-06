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

output "temporal_cluster_name" {
  value       = var.enable_temporal ? module.temporal[0].cluster_name : null
  description = "Created Temporal ECS cluster name."
}

output "temporal_service_name" {
  value       = var.enable_temporal ? module.temporal[0].service_name : null
  description = "Created Temporal ECS service name."
}

output "temporal_ui_dns_name" {
  value       = var.enable_temporal ? module.temporal[0].ui_dns_name : null
  description = "Open this DNS name to access the Temporal UI when Temporal is enabled."
}
