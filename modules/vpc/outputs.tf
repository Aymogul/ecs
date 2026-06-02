output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "A list of public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "A list of private subnet IDs"
}

output "nat_gateway_id" {
  value       = aws_nat_gateway.this.id
  description = "The ID of the NAT Gateway"
}
