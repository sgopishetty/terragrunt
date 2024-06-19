variable "vpc_id" {
  description = "The ID of the VPC where subnets will be created"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
}

variable "public_subnet_tags" {
  description = "Tags to apply to the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Tags to apply to the private subnets"
  type        = map(string)
  default     = {}
}

variable "region" {
  type = string
}

variable "nat_gateway_id" {
  type = string
}

variable "env" {
  type = string
}

variable "internet_gateway_id" {
  type = string
}