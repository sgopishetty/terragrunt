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
    priority = number
  }))
}

variable "alb_arns" {
  type = list(string)
  description = "List of ALB ARNs to associate with the Web ACL"
}

variable "custom_rules_json" {
  description = "Custom JSON rules including RuleActionOverrides and other statements"
  type = list(object({
    Name            = string
    Priority        = number
    Statement       = map(any)  # Allows for varied structures in Statement
    OverrideAction  = map(any)  # Allows for varied structures in OverrideAction
    VisibilityConfig = object({
      SampledRequestsEnabled = bool
      CloudWatchMetricsEnabled = bool
      MetricName = string
    })
  }))
}

# Variable for regex rules
variable "custom_regex_rules_json" {
  description = "Regex rules for traffic filtering"
  type = list(object({
    Name            = string
    Priority        = number
    Statement       = object({
      NotStatement = object({
        Statement = object({
          RegexMatchStatement = object({
            RegexString      = string
            FieldToMatch     = object({
              UriPath = map(any)
            })
            TextTransformations = list(object({
              Priority = number
              Type     = string
            }))
          })
        })
      })
    })
    Action = object({
      Block = map(any)  # Allows for flexibility if needed
    })
    VisibilityConfig = object({
      SampledRequestsEnabled   = bool
      CloudWatchMetricsEnabled = bool
      MetricName               = string
    })
  }))
}

variable "git_waf_rules" {
  description = "Git WAF rules"
  type = list(object({
    Name       = string
    Priority   = number
    Statements = list(object({
      LabelScope       = string
      LabelKey         = string
      RegexString      = string
    }))
    MetricName = string
  }))
}