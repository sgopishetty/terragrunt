resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = index(var.rules, rule.value)

      # Override action for counting requests instead of blocking
      override_action {
        none {}  # Set to 'block {}' to block instead of count
      }

      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.value.rule_id

          
          # Exclude specific rules for AWSManagedRulesAnonymousIpList
          dynamic "excluded_rule" {
            for_each = rule.value.rule_id == "AWSManagedRulesAnonymousIpList" ? ["HostingProviderIPList"] : []
            content {
              name = excluded_rule.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }
}


# Association between WAF and ALB
resource "aws_wafv2_web_acl_association" "this" {
  for_each    = toset(var.alb_arns) # Iterate over the list of ALB ARNs
  resource_arn = each.value          # ARN of the ALB to associate the Web ACL with
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}