variable "name" {
  description = "The name of the WAF Web ACL"
  type        = string
}

variable "scope" {
  description = "The scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
}

variable "rules" {
  description = "List of rules to apply to the Web ACL"
  type = list(object({
    name    = string
    rule_id = string
  }))
}

variable "alb_arn" {
  description = "The ARN of the Application Load Balancer to associate with the WAF"
  type        = string
}