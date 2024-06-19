output "public_subnets" {
  description = "The public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "The private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table" {
  description = "The public route table"
  value       = aws_route_table.public.id
}

output "private_route_table" {
  description = "The private route table"
  value       = aws_route_table.private.id
}
