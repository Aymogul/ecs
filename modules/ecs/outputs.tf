output "ecs_cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "The name of the ECS cluster"
}

output "ecs_service_name" {
  value       = aws_ecs_service.this.name
  description = "The name of the ECS service"
}

output "ecs_task_execution_role_arn" {
  value       = aws_iam_role.task_execution.arn
  description = "The ARN of the ECS task execution role"
}
