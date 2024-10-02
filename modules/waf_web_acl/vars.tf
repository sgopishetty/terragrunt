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
    name                = string
    rule_id             = optional(string)  # For managed rules, rule_id will be provided
    priority            = number            # Priority for the rule
    excluded_rules      = optional(list(string))  # List of sub-rules to exclude from managed rule group
    override_action     = optional(string)  # Override action (e.g., "count")
    regex_match_statement = optional(list(object({  # For custom regex match statements
      regex_string                = string
      text_transformation_priority = number
      text_transformation_type    = string
    })))
    and_statement = optional(list(object({  # For complex rules with label and not-statement
      label_match_statement_scope = string
      label_match_statement_key   = string
      not_statement = object({
        regex_string                = string
        text_transformation_priority = number
        text_transformation_type    = string
      })
    })))
  }))
}

variable "alb_arns" {
  type = list(string)
  description = "List of ALB ARNs to associate with the Web ACL"
}
