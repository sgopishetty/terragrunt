resource "aws_wafv2_web_acl" "this" {
  name  = var.name
  scope = var.scope

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled    = true
  }

  dynamic "rule" {
    for_each = var.rules
    content {
      name     = rule.value.name
      priority = index(var.rules, rule.value)

      # Define override action for AWSManagedRulesAnonymousIpList
      override_action {
        # Check if the current rule requires an override action
        dynamic "rule_action_override" {
          for_each = rule.value.name == "AWSManagedRulesAnonymousIpList" ? [1] : []
          content {
            name = "HostingProviderIPList"  # Specify the override rule action here
            action_to_use {
              count {}  # Use count action
            }
          }
        }
      }

      statement {
        managed_rule_group_statement {
          vendor_name = "AWS"
          name        = rule.value.rule_id
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled    = true
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