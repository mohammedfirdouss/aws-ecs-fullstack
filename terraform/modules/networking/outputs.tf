output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for az in local.azs : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = [for az in local.azs : aws_subnet.private[az].id]
}

output "isolated_subnet_ids" {
  description = "List of isolated subnet IDs."
  value       = [for az in local.azs : aws_subnet.isolated[az].id]
}
